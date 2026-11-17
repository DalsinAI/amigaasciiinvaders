#!/bin/sh
# Host tests for the Amiga port of ascii-invaders: upstream's game
# (amiga/patches applied, __amigaos__ set, so the Amiga's code paths are
# the ones built: no SIGALRM, frames run between keys by amiga/frames.c)
# with GFOpenCurses over a plain terminal (its src/console_host.c),
# played with scripted keys; GFOpenCurses' tests/host/vt.py reads back the screen as
# the Amiga's console would show it:
#  - the frame loop: TICK runs FPS times a second while no key comes, and
#    a key comes back at once; curses' deleteln and insertln;
#  - the intro: the title, the invaders and their points, the address;
#    the window's close there ends the game;
#  - Space starts a game: the shelters and, a few frames on, the invaders;
#    the gunner appears and j and k move it; q leaves.
# Needs a C compiler and python3; skipped without a compiler.
#   UP=/path/to/ascii-invaders (patched) GFOPENCURSES=/path/to/gfopencurses \
#       sh tests/host/test_asciiinvaders.sh
# Copyright (c) 2026 AmiCradle Team. GPL-2.0-or-later, like ascii-invaders.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
UP=${UP:?UP=upstream source}
GC=${GFOPENCURSES:?GFOPENCURSES=gfopencurses checkout}
VT=$GC/tests/host/vt.py
CC=${HOSTCC:-cc}
command -v "$CC" >/dev/null 2>&1 || { echo "host tests: skipped (no C compiler)"; exit 0; }
T=$(mktemp -d "${TMPDIR:-/tmp}/asciiinvaders-host.XXXXXX")
[ -n "${TEST_KEEP:-}" ] || trap 'rm -rf "$T"' EXIT INT TERM
cd "$ROOT"

MINE="-std=gnu99 -Wall -Werror -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -I$GC/include -Iamiga/include -Iamiga"
for f in curses keys; do $CC $MINE -c -o "$T/$f.o" "$GC/src/$f.c"; done
$CC $MINE -c -o "$T/con.o" "$GC/src/console_host.c"
$CC $MINE -c -o "$T/frames.o" amiga/frames.c
$CC -std=gnu99 -w -D__amigaos__ -include amiga/include/amiga_prelude.h -I$GC/include -Iamiga/include -Iamiga \
    -c -o "$T/inv.o" "$UP/invaders.c"
$CC -o "$T/invaders" "$T/inv.o" "$T/curses.o" "$T/keys.o" "$T/frames.o" "$T/con.o"

fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }

cat > "$T/units.c" <<'C'
#include <stdio.h>
#include "curses.h"
#include "amiga_prelude.h"
static int ticks;
static void tick(int s) { (void)s; ticks++; }
int main(void)
{
	unsigned long t0;
	int c;
	initscr();
	t0 = acurses_ms();
	c = amiga_frames_getch(tick, 20);	/* the key comes after 0.5 s */
	endwin();
	printf("%c %d %lu\n", c, ticks, acurses_ms() - t0);
	if (!(c == 'x' && ticks >= 8 && ticks <= 11)) return 1;
	/* deleteln: the lines below move up, the last is blank */
	initscr();
	mvaddstr(1, 0, "one"); mvaddstr(2, 0, "two"); mvaddstr(LINES - 1, 0, "last");
	move(1, 0); deleteln();
	if ((mvinch(1, 0) & A_CHARTEXT) != 't' || (mvinch(LINES - 2, 0) & A_CHARTEXT) != 'l'
	    || (mvinch(LINES - 1, 0) & A_CHARTEXT) != ' ') { printf("deleteln\n"); return 1; }
	move(1, 0); insertln();
	if ((mvinch(1, 0) & A_CHARTEXT) != ' ' || (mvinch(2, 0) & A_CHARTEXT) != 't'
	    || (mvinch(LINES - 1, 0) & A_CHARTEXT) != 'l') { printf("insertln\n"); return 1; }
	endwin();
	return 0;
}
C
$CC $MINE -o "$T/units" "$T/units.c" "$T/curses.o" "$T/keys.o" "$T/frames.o" "$T/con.o"
if { sleep 0.5; printf x; } | "$T/units" > "$T/units.out"; then
    ok "frames: 20 a second run while waiting, then the key; deleteln, insertln"
else bad "frames: $(tail -n 1 "$T/units.out")"; fi

run() {	# output, then the steps: keys (printf format) and pauses (s:SECONDS)
    out=$1; shift
    (cd "$T" && for step in "$@"; do
        case $step in s:*) sleep "${step#s:}" ;; *) printf "$step" ;; esac
    done | timeout 30 ./invaders > "$out" 2>&1)
}
want() { name=$1; out=$2; shift 2
    if python3 "$VT" "$out" "$@" > "$T/vt.txt"; then ok "$name"; else bad "$name"; cat "$T/vt.txt"; fi; }
gunx() {	# the column of the gunner's turret (the bottom lines)
    python3 "$VT" "$1" | sed -n '22,24p' | awk '{ i = index($0, "mAm"); if (i) { print i; exit } }'
}

if run "$T/intro.out" s:0.3; then ok "the window's close ends the game"; else bad "the end of the input did not end it"; fi
want "the intro: title, invaders and points, address" "$T/intro.out" \
    --want "= 30 points" --want "= 20 points" --want "= 10 points" --want "= ?  points" \
    --want "github.com/macdice/ascii-invaders" --want "__ _ ___  ___"
run "$T/play.out" ' ' s:4
want "Space starts a game: the shelters and the gunner" "$T/play.out" --want "/MMMMM\\" --want "MAZAM"
python3 "$VT" "$T/play.out" > "$T/play.txt"
if [ "$(grep -c '[^ ]' "$T/play.txt")" -ge 10 ] && ! grep -q "= 30 points" "$T/play.txt"; then ok "the invaders' rows are drawn"; else bad "the invaders"; cat "$T/play.txt"; fi
g0=$(gunx "$T/play.out")
run "$T/left.out" ' ' s:4 jjj s:0.5
g1=$(gunx "$T/left.out")
if [ -n "$g0" ] && [ -n "$g1" ] && [ "$g1" -lt "$g0" ]; then ok "j moves the gunner left ($g0 to $g1)"; else bad "j: gunner ${g0:-none} to ${g1:-none}"; python3 "$VT" "$T/left.out"; fi
run "$T/right.out" ' ' s:4 kkk s:0.5
g2=$(gunx "$T/right.out")
if [ -n "$g2" ] && [ "$g2" -gt "$g0" ]; then ok "k moves it right ($g0 to $g2)"; else bad "k: gunner ${g0:-none} to ${g2:-none}"; fi
if run "$T/quit.out" ' ' s:1 q s:1; then ok "q leaves the game"; else bad "q"; fi

if [ "$fails" = 0 ]; then echo "host tests: all passed"; else echo "host tests: $fails failed"; exit 1; fi
