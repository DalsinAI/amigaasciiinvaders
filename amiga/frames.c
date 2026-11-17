/* ascii-invaders' clock, without signals: upstream sets an interval timer
 * (setitimer, SIGALRM, FPS times a second) whose handler moves everything
 * while main() waits in getch() for a key. AmigaOS has no SIGALRM, and
 * upstream's own TODO asks for a wait with a timeout instead: here getch
 * waits only until the next frame is due (curses' timeout: dos.library
 * WaitForChar on the Amiga), runs the frame (TICK) for each one due, and
 * gives back the first key that comes. Frames that fall far behind (the
 * window was held) are dropped rather than run in a burst.
 * Copyright (c) 2026 AmiCradle Team. GPL-2.0-or-later, like ascii-invaders. */
#include "curses.h"
#include "amiga_prelude.h"

int amiga_frames_getch(void (*tick)(int), int fps)
{
	static unsigned long next;
	unsigned long period = 1000UL / (unsigned long)(fps > 0 ? fps : 1);
	int c;

	if (!next) next = acurses_ms() + period;
	for (;;) {
		long left = (long)(next - acurses_ms());
		if (left <= 0) {
			tick(0);
			next += period;
			if ((long)(acurses_ms() - next) > (long)(10 * period))
				next = acurses_ms() + period; /* far behind: start again from now */
			continue;
		}
		wtimeout(stdscr, (int)left);
		c = wgetch(stdscr);
		wtimeout(stdscr, -1);
		if (c != ERR) return c;
	}
}
