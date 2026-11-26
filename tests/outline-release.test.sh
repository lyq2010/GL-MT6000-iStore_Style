#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/outline-release-test.XXXXXX")
trap 'rm -rf "$work"' EXIT
# Execute the production resolver without running router installation commands.
sed -n '/^resolve_outline_release() {$/,/^}$/p' "$root/glinet-istore-argon-clean-op25.sh" > "$work/resolver.sh"
test -s "$work/resolver.sh"
. "$work/resolver.sh"
# The sourced production function consumes this input and assigns the outputs.
# shellcheck disable=SC2034
outline_repo=lyq2010/lees-outline
outline_version='' outline_sha='' outline_url=''
fail() { echo "$*" >&2; exit 1; }
hash=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
printf '%s  luci-theme-outline-2.0.0-r1.apk\n%s  luci-theme-outline_2.0.0-r1_all.ipk\n' "$hash" "$hash" > "$work/sums"
resolve_outline_release "$work/sums"
[ "$outline_version" = 2.0.0-r1 ] && [ "$outline_sha" = "$hash" ]
[ "$outline_url" = https://github.com/lyq2010/lees-outline/releases/download/v2.0.0/luci-theme-outline-2.0.0-r1.apk ]
echo 'PASS: current release APK selected, IPK ignored'
printf '%s  luci-theme-outline-2.1.3-r7.apk\n' "$hash" > "$work/sums"
resolve_outline_release "$work/sums"
[ "$outline_version" = 2.1.3-r7 ]
[ "$outline_url" = https://github.com/lyq2010/lees-outline/releases/download/v2.1.3/luci-theme-outline-2.1.3-r7.apk ]
echo 'PASS: a future release needs no script version change; download uses immutable tag'
reject() {
    if (resolve_outline_release "$work/sums") > "$work/rejected.log" 2>&1; then
        echo 'FAIL: invalid release accepted'; exit 1
    fi
}
cat "$work/sums" "$work/sums" > "$work/duplicate"
cp "$work/duplicate" "$work/sums"
reject
echo 'PASS: duplicate APK rejected'
: > "$work/sums"
reject
echo 'PASS: missing checksum rejected'
printf '%s  ../../luci-theme-outline-2.1.3-r7.apk\n' "$hash" > "$work/sums"
reject
echo 'PASS: unexpected path rejected'
printf 'invalid  luci-theme-outline-2.1.3-r7.apk\n' > "$work/sums"
reject
echo 'PASS: malformed hash rejected'
