# ascii-invaders for GFOS

The AmiCradle Team's port of Thomas Munro's ascii-invaders, Space Invaders
in ASCII art, to GFOS: AmigaOS 3.2 with GFOpenUp, 68040/68060. It runs in
its own 80 x 24 console window, in colour: no SDL, no ACGame and no
GFOpenGPU. It ships as a release archive with an Installer and as the
GFOpenUp part Parts/AsciiInvaders.

Upstream is fetched at build time (package/asciiinvaders.lock) and patched
(amiga/patches); this repository holds only the Amiga port. See
[AMIGA_PORT.md](AMIGA_PORT.md).

GPL-2.0-or-later, like ascii-invaders. Copyright (c) 2026 AmiCradle Team.
