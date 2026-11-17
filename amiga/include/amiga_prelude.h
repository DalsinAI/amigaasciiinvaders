/* Included before ascii-invaders' invaders.c in the Amiga build and the
 * host tests (-include): the frame loop that stands in for its SIGALRM
 * timer (amiga/frames.c).
 * Copyright (c) 2026 AmiCradle Team. GPL-2.0-or-later, like ascii-invaders. */
#ifndef AMIGA_PRELUDE_H
#define AMIGA_PRELUDE_H
/* the next key; TICK(0) runs for each 1/FPS s that passes meanwhile */
int amiga_frames_getch(void (*tick)(int), int fps);
#endif
