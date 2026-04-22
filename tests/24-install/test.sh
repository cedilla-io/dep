home="$WORK/home-install"
mkdir -p "$home"

cat "$DEP_ROOT/install.sh" | HOME="$home" SHELL=/bin/bash DEP_REPO_URL="file://$DEP_ROOT" sh

assert "install crée le binaire" "test -x '$home/.local/bin/dep'"
assert "dep fonctionne après install" "HOME='$home' '$home/.local/bin/dep' --version >/dev/null 2>&1"
