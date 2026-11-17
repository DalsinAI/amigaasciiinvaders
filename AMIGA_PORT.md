ascii-invaders for GFOS
=======================

Thomas Munro's ascii-invaders (2001, 2013): Space Invaders in ASCII art.
Rows of invaders march across and down, dropping bombs; shoot them from
behind your shelters before they land. The mothership is worth a mystery
score.

Space starts a game and fires; j and k (or the cursor keys) move the
gunner; q leaves.

What it needs
-------------
GFOS (AmigaOS 3.2 with GFOpenUp) on a 68040 or 68060; no FPU. The game
runs in an 80 x 24 console window, in colour on a screen with eight pens:
no SDL, no ACGame, no GFOpenGPU.

How it was ported
-----------------
The game is built from upstream as it is, with our curses
(amiga/curses.c, shared with our other console ports), which gains
deleteln() and insertln() here. Upstream moves everything from a SIGALRM
interval timer, 15 times a second, while main() waits in getch(), and its
own TODO asks for a wait with a timeout instead: amiga/frames.c waits in
curses only until the next frame is due (dos.library WaitForChar, with
DateStamp for the clock), runs each frame that is due, and returns the
key that comes. The one patch, amiga/patches/0001, calls it in place of
the timer, and leaves out --unicode (the console font is Latin-1).

Tests: tests/host/test_asciiinvaders.sh builds the game on the build
machine over a plain terminal with the Amiga code paths, plays it with
scripted keys and pauses and reads back the screen (the intro, the window's
close, Space and the shelters, the gunner, the invaders' rows, j and k,
q), and checks the frame loop's rate, deleteln and insertln.

Credits
-------
ascii-invaders (c) 2001, 2013 Thomas Munro, GPL-2.0-or-later (LICENSE.txt;
ReadMe-ascii-invaders is upstream's README).
Amiga port: Designed, tested and delivered by The AmiCradle Team.
Copyright (c) 2026 AmiCradle Team, GPL-2.0-or-later like ascii-invaders.
