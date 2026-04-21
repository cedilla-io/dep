dep_sync_help()(
  echo "  sync       Installe les dépendances du projet"
)

dep_sync()(
  root=$(dep_find_root) || { echo "pas de @manifest trouvé"; return 1; }
  cd "$root"

  hooks_file="$(dep_store_path "$(pwd)")/.hooks_pending"
  mkdir -p "$(dep_store_path "$(pwd)")"
  trap 'rm -f "$hooks_file"' EXIT
  : > "$hooks_file"

  dep_sync_tree "$(pwd)" "$(pwd)" "" "$hooks_file" || return 1

  trusted=""
  while IFS= read -r entry; do
    test -n "$entry" || continue
    hook_proto="${entry%% *}"
    hook_dir="${entry#* }"
    case "$hook_proto" in
      fs)
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
        test "$trusted" = yes && dep_run_hook "$hook_dir" install
        ;;
    esac
  done < "$hooks_file"
)

dep_sync_tree()(
  pkg_dir="$1" root_dir="$2" visited="$3" hooks_file="$4"

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

  mkdir -p "$(dep_store_path "$root_dir")"

  new_locks=""
  nl='
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

      dep_link "$target" "$(dep_store_entry_path "$root_dir" "$name")"

      test "$pkg_dir" != "$root_dir" &&
        dep_link "$target" "$(dep_store_entry_path "$pkg_dir" "$name")"

      new_locks=$(dep_append_line "$new_locks" "$dep")

    elif test "$proto" = "git"; then
      ref_name="${ref:-HEAD}"

      case "$source" in
        /*)
          local_source=$(dep_abs_path "$source") || return 1
          source_url="file://$local_source"
          hash=$(git -C "$local_source" rev-parse "$ref_name")
          ;;
        ./*|../*)
          local_source=$(dep_abs_path "$pkg_dir/$source") || return 1
          source_url="file://$local_source"
          hash=$(git -C "$local_source" rev-parse "$ref_name")
          ;;
        *)
          source_url="https://$source"
          hash=$(dep_git "$pkg_dir" ls-remote "$source_url" "$ref_name" | cut -f1 | head -1)
          ;;
      esac

      store=$(dep_store_entry_path "$root_dir" "$name#$hash")

      if ! test -d "$store"; then
        if test -n "$ref"; then
          dep_git "$pkg_dir" clone --depth 1 --branch "$ref" --recurse-submodules --shallow-submodules "$source_url" "$store"
        else
          dep_git "$pkg_dir" clone --depth 1 --recurse-submodules --shallow-submodules "$source_url" "$store"
        fi
      fi

      dep_link "$store" "$(dep_store_entry_path "$root_dir" "$name")"

      test "$pkg_dir" != "$root_dir" &&
        dep_link "$store" "$(dep_store_entry_path "$pkg_dir" "$name")"

      new_locks=$(dep_append_line "$new_locks" "$source#$hash")
    fi
  done
  set +f
  IFS=$old_ifs

  dep_write_lockfile "$lockfile_path" "$DEP_VERSION" "$new_locks"

  nl='
'
  old_ifs=$IFS
  IFS=$nl
  set -f
  for dep in $new_locks; do
    test -n "$dep" || continue
    eval "$(dep_parse "$dep")"
    dep_path=$(dep_store_entry_path "$root_dir" "$name")
    test -L "$dep_path" || test -d "$dep_path" || continue
    real_path=$(dep_resolve_dir "$dep_path") || continue
    if test -f "$(dep_manifest_path "$real_path")"; then
      dep_sync_tree "$real_path" "$root_dir" "$visited" "$hooks_file"
      if dep_has_scripts "$real_path"; then
        printf '%s %s\n' "$proto" "$real_path" >> "$hooks_file"
      fi
    fi
  done
  set +f
  IFS=$old_ifs
  return 0
)
