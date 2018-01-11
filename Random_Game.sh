#!/bin/sh
#
# Script by Daniel Radtke <DanTheMan827>
#

source /etc/preinit
script_init

cachePath="/tmp/RandomGame-FileList"
lastLaunchArgsPath="/tmp/RandomGame-LaunchArguments"
lastCommandPath="/tmp/RandomGame-LastCommand"

script_gamecode="$(basename $(dirname $0))"

if (echo "$*" | grep -qEe "rollback-input-dir|load-state"); then
  exec $(cat "$lastCommandPath") $@
fi

gameStorage="$rootfs$gamepath"
type findGameStorage && gameStorage="$(findGameStorage)"

if [ -f "$cachePath" ]; then
  fileList="$(cat "$cachePath")"
else
  fileList="$(find "$gameStorage" -name "*.desktop")"
  echo "$fileList" > "$cachePath"
fi

fileList="$(echo "$fileList" | grep -ve "$script_gamecode")"
[ "$sftype" != "nes" ] && fileList="$(echo "$fileList" | grep -ve "^$gameStorage/nes/")"

while true
do
  desktopFile="$(echo "$fileList" | head -$((${RANDOM} % `echo "$fileList" | wc -l` + 1)) | tail -1)"
  grep "$desktopFile" -qEe "chmenu|^Random=false|/bin/hsqs |/bin/sh " || break
done

execLine="$(cat "$desktopFile" | grep -E '^Exec=')"
pathLine="$(cat "$desktopFile" | grep -E '^Path=')"
codeLine="$(cat "$desktopFile" | grep -E '^Code=')"
desktopFilePath="$(dirname "$desktopFile")"
desktopExec="${execLine##Exec=}"
desktopPath="${pathLine##Path=}"
desktopCode="${codeLine##Code=}"
desktopExec="$(echo "$desktopExec" | sed -e "s# \(/usr/share/games/\(nes/kachikachi/\)\?\|/var/games/\)$desktopCode/# $desktopFilePath/#")"
echo "$desktopExec"
pwd="$(pwd)"

mkdir -p "$desktopPath"

cd /
umount "$pwd" 2>/dev/null
mount_bind "$desktopPath" "$pwd"
cd "$pwd"

echo "$@" > "$lastLaunchArgsPath"
echo "$desktopExec" > "$lastCommandPath"

exec $desktopExec $@
