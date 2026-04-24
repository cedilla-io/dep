dep_sync_help()(
  echo "  sync       Installe les dépendances du projet"
)

dep_sync()(
  root=$(dep_find_root) || { echo "pas de @manifest trouvé"; return 1; }
  cd "$root"

  hooks_file="$(dep_store_path "$(pwd)")/.hooks_pending"
  links_file="$(dep_store_path "$(pwd)")/.links_desired"
  hashes_file="$(dep_store_path "$(pwd)")/.hashes_desired"
  mkdir -p "$(dep_store_path "$(pwd)")"
  trap 'rm -f "$hooks_file" "$links_file" "$hashes_file"' EXIT
  : > "$hooks_file"
  : > "$links_file"
  : > "$hashes_file"

  dep_verbose "sync: root=$root"
  dep_sync_tree "$(pwd)" "$(pwd)" "" "$hooks_file" "$links_file" "$hashes_file" || return 1
  dep_sync_prune_store "$(pwd)" "$links_file" "$hashes_file"

  trusted=""
  while IFS= read -r entry; do
    test -n "$entry" || continue
    hook_proto="${entry%% *}"
    hook_dir="${entry#* }"
    case "$hook_proto" in
      fs)
        dep_verbose "hook install(fs): $hook_dir"
        dep_run_hook "$hook_dir" install
        ;;
      git)
        if test -z "$trusted"; then
          if dep_trust_prompt "$(pwd)"; then
            trusted=yes
          else
            trusted=no
          fi
        fi
        if test "$trusted" = yes; then
          dep_verbose "hook install(git): $hook_dir"
          dep_run_hook "$hook_dir" install
        fi
        ;;
    esac
  done < "$hooks_file"
)

dep_sync_line_in_file()(
  needle="$1"
  file="$2"
  grep -Fqx "$needle" "$file" 2>/dev/null
)

dep_sync_prune_store()(
  root_dir="$1"
  links_file="$2"
  hashes_file="$3"
  store=$(dep_store_path "$root_dir")

  test -d "$store" || return 0

  for entry in "$store"/*; do
    base=${entry##*/}
    case "$base" in
      ''|'.hooks_pending'|'.links_desired'|'.hashes_desired'|"$DEP_TRUST_FILE") continue ;;
      .*) continue ;;
      *"#"*)
        if ! dep_sync_line_in_file "$base" "$hashes_file"; then
          dep_verbose "prune store hash: $base"
          rm -rf "$entry"
        fi
        ;;
      *)
        if ! dep_sync_line_in_file "$base" "$links_file"; then
          dep_verbose "prune store link: $base"
          rm -rf "$entry"
        fi
        ;;
    esac
  done
)

dep_sync_line_in_lines()(
  needle="$1"
  lines="${2-}"

  test -n "$lines" || return 1

  nl='\
'
  old_ifs=$IFS
  IFS=$nl
  set -f
  for line in $lines; do
    test "$line" = "$needle" && set +f && IFS=$old_ifs && return 0
  done
  set +f
  IFS=$old_ifs
  return 1
)

dep_sync_prune_pkg_store()(
  pkg_dir="$1"
  kept_links="${2-}"
  store=$(dep_store_path "$pkg_dir")

  test -d "$store" || return 0

  for entry in "$store"/*; do
    base=${entry##*/}
    case "$base" in
      ''|"$DEP_TRUST_FILE"|'.hooks_pending'|'.links_desired'|'.hashes_desired') continue ;;
      .*) continue ;;
    esac
    if ! dep_sync_line_in_lines "$base" "$kept_links"; then
      dep_verbose "prune package store: $pkg_dir -> $base"
      rm -rf "$entry"
    fi
  done
)

dep_sync_lock_hash_for_dep()(
  dep_entry="$1"
  lock_entries="${2-}"

  test -n "$lock_entries" || return 1

  nl='\
'
  old_ifs=$IFS
  IFS=$nl
  set -f
  for lock_entry in $lock_entries; do
    case "$lock_entry" in
      "$dep_entry"#*)
        printf '%s\n' "${lock_entry##*#}"
        set +f
        IFS=$old_ifs
        return 0
        ;;
    esac
  done
  set +f
  IFS=$old_ifs
  return 1
)

dep_sync_tree()(
  pkg_dir="$1" root_dir="$2" visited="$3" hooks_file="$4" links_file="$5" hashes_file="$6"

  case ":$visited:" in *":$pkg_dir:"*) return ;; esac
  visited="$visited:$pkg_dir"

  manifest_path=$(dep_manifest_path "$pkg_dir")
  lockfile_path=$(dep_lockfile_path "$pkg_dir")

  test -f "$manifest_path" || return 0

  manifest_version=$(dep_read_version "$manifest_path")
  dep_require_manifest_version "$manifest_version" || return 1

  if test -f "$lockfile_path"; then
    lock_version=$(dep_read_version "$lockfile_path")
    dep_require_lockfile_version "$lock_version" || return 1
  fi

  deps=$(dep_read_entries "$manifest_path")
  lock_entries=""
  if test -f "$lockfile_path"; then
    lock_entries=$(dep_read_entries "$lockfile_path")
  fi

  mkdir -p "$(dep_store_path "$root_dir")"
  if test -L "$(dep_store_path "$pkg_dir")"; then
    rm -f "$(dep_store_path "$pkg_dir")"
  fi
  mkdir -p "$(dep_store_path "$pkg_dir")"

  new_locks=""
  resolved_links=""
  nl='\
'
  old_ifs=$IFS
  IFS=$nl
  set -f
  for dep in $deps; do
    test -n "$dep" || continue
    eval "$(dep_parse "$dep")"

    if test "$proto" = "fs"; then
      case "$source" in
        /*) target=$(dep_abs_path "$source") || return 1 ;;
        *)  target=$(dep_abs_path "$pkg_dir/$source") || return 1 ;;
      esac

      dep_verbose "link fs: $name -> $target"
      dep_link "$target" "$(dep_store_entry_path "$root_dir" "$name")"
      if test "$pkg_dir" != "$root_dir"; then
        dep_verbose "link fs nested: $pkg_dir/.@/$name -> $(dep_store_entry_path "$root_dir" "$name")"
        dep_link "$(dep_store_entry_path "$root_dir" "$name")" "$(dep_store_entry_path "$pkg_dir" "$name")"
      fi
      printf '%s\n' "$name" >> "$links_file"

      new_locks=$(dep_append_line "$new_locks" "$dep")
      resolved_links=$(dep_append_line "$resolved_links" "$name")

    elif test "$proto" = "git"; then
      ref_name="${ref:-HEAD}"
      ref_key=$(dep_ref_key "$ref_name")
      name_ref="$name@$ref_key"
      hash=""

      if locked_hash=$(dep_sync_lock_hash_for_dep "$dep" "$lock_entries"); then
        hash="$locked_hash"
        dep_verbose "lock hit: $dep -> $hash"
      fi

      case "$source" in
        /*)
          local_source=$(dep_abs_path "$source") || return 1
          source_url="file://$local_source"
          test -n "$hash" || hash=$(git -C "$local_source" rev-parse "$ref_name")
          ;;
        ./*|../*)
          local_source=$(dep_abs_path "$pkg_dir/$source") || return 1
          source_url="file://$local_source"
          test -n "$hash" || hash=$(git -C "$local_source" rev-parse "$ref_name")
          ;;
        *)
          if ! dep_is_git_remote_source "$source"; then
            echo "source git non supportée: $source"
            echo "utiliser [git@]host:owner/repo[.git][@ref], https://host/owner/repo[.git][@ref] ou un chemin local"
            return 1
          fi
          if test -n "$hash"; then
            source_url=""
          else
            resolved=$(dep_git_resolve_remote "$pkg_dir" "$source" "$ref_name") || {
              candidates=$(dep_git_candidates_join "$source")
              echo "impossible de résoudre $source ($ref_name) via candidats git: $candidates"
              return 1
            }
            source_url=${resolved% *}
            hash=${resolved##* }
          fi
          ;;
      esac

      store=$(dep_store_entry_path "$root_dir" "$name#$hash")

      if ! test -d "$store"; then
        if test -n "$source_url"; then
          dep_verbose "clone git: $source_url -> $store"
          dep_git "$pkg_dir" clone --recurse-submodules "$source_url" "$store" || return 1
        else
          resolved_clone_source=$(dep_git_try_candidates "$pkg_dir" "$source" dep_git_clone_candidate "$store") || {
            candidates=$(dep_git_candidates_join "$source")
            echo "impossible de cloner $source via candidats git: $candidates"
            return 1
          }
          source_url="$resolved_clone_source"
          dep_verbose "clone git fallback: $source_url -> $store"
        fi
        dep_verbose "checkout git: $name@$ref_name -> $hash"
        dep_git "$pkg_dir" -C "$store" checkout -q "$hash" || return 1
      else
        dep_verbose "reuse git store: $store"
      fi

      dep_verbose "link git: $name_ref -> $store"
      dep_link "$store" "$(dep_store_entry_path "$root_dir" "$name_ref")"
      if test "$pkg_dir" != "$root_dir"; then
        dep_verbose "link git nested: $pkg_dir/.@/$name_ref -> $(dep_store_entry_path "$root_dir" "$name_ref")"
        dep_link "$(dep_store_entry_path "$root_dir" "$name_ref")" "$(dep_store_entry_path "$pkg_dir" "$name_ref")"
      fi
      printf '%s\n' "$name_ref" >> "$links_file"
      printf '%s\n' "$name#$hash" >> "$hashes_file"

      new_locks=$(dep_append_line "$new_locks" "$dep#$hash")
      resolved_links=$(dep_append_line "$resolved_links" "$name_ref")
    fi
  done
  set +f
  IFS=$old_ifs

  dep_write_lockfile "$lockfile_path" "$DEP_VERSION" "$new_locks"
  if test "$pkg_dir" != "$root_dir"; then
    dep_sync_prune_pkg_store "$pkg_dir" "$resolved_links"
  fi

  nl='\
'
  old_ifs=$IFS
  IFS=$nl
  set -f
  for link_name in $resolved_links; do
    test -n "$link_name" || continue
    dep_path=$(dep_store_entry_path "$pkg_dir" "$link_name")
    test -L "$dep_path" || test -d "$dep_path" || continue
    real_path=$(dep_resolve_dir "$dep_path") || continue
    if test -f "$(dep_manifest_path "$real_path")"; then
      dep_sync_tree "$real_path" "$root_dir" "$visited" "$hooks_file" "$links_file" "$hashes_file"
      dep_proto=fs
      case "$link_name" in *"@"*) dep_proto=git ;; esac
      if dep_has_scripts "$real_path"; then
        dep_verbose "queue hook($dep_proto): $real_path"
        printf '%s %s\n' "$dep_proto" "$real_path" >> "$hooks_file"
      fi
    fi
  done
  set +f
  IFS=$old_ifs
  return 0
)
