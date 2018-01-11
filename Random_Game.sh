#!/bin/sh
#
# Script by Daniel Radtke <DanTheMan827>
#

source /etc/preinit
script_init

script_gamecode="$(basename $(dirname $0))"

if [ "$(echo "$*" | grep "rollback-input-dir")" != "" ]; then
  exec $(cat /tmp/RandomGame-LastCommand) $@
fi

gameStorage="$rootfs$gamepath"
type findGameStorage && gameStorage="$(findGameStorage)"

flist="$(find "$gameStorage" -name "*.desktop" | grep -ve "$script_gamecode")"
while true
do
  dfile="$(echo "$flist" | head -$((${RANDOM} % `echo "$flist" | wc -l` + 1)) | tail -1)"
  grep "$dfile" -qEe "chmenu|^Random=false|/bin/hsqs |/bin/sh" || break
  [ "$sftype" != "nes" ] && (grep "$dfile" -qEe "^$gameStorage/nes/" || break)
done

eline="$(cat "$dfile" | grep -E '^Exec=')"
pline="$(cat "$dfile" | grep -E '^Path=')"
cline="$(cat "$dfile" | grep -E '^Code=')"
fpath="$(dirname "$dfile")"
dcommand="${eline##Exec=}"
dpath="${pline##Path=}"
dcode="${cline##Code=}"
dcommand="$(echo "$dcommand" | sed -e "s# \(/usr/share/games/\(nes/kachikachi/\)\?\|/var/games/\)$dcode/# $fpath/#")"
echo "$dcommand"
pwd="$(pwd)"

mkdir -p "$dpath"

cd /
umount "$pwd" 2>/dev/null
mount_bind "$dpath" "$pwd"
cd "$pwd"

echo "$@" > "/tmp/RandomGame-LaunchArguments"
echo "$dcommand" > "/tmp/RandomGame-LastCommand"

exec $dcommand $@