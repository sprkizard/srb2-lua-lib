Axis2D script
by sprki_zard and Fickleheart
Version 1.3 (Alpha)
Setup documentation
---------------

Loading into a PK3/WAD:

For testing, adding the script separately will work. Otherwise, load l_Axis2D.lua into
your PK3 by dropping it inside of the Lua sub-folder. For WAD files, use any lump name that triggers
the game to load it as a Lua script. (The suggested lump name is LUA_AX2D.)



Thing types:

Axis (1700): Set up similar to a NiGHTS axis, but without multimare settings. Angle
is axis radius (add 16384 to invert), and the flags value is the axis number. (Tip:
Zone Builder has a rendering option to draw the axis circles in-editor.)

Line Axis (1702): Same thing type as NiGHTS axis transfer line, but set up slightly
differently. Angle is the direction pressing right should take the player, and the
flags value is the axis number. No second Thing is necessary per axis. Players may
slide a bit when behind (to the left camera-wise of) the reference object, so put it
as far back as needed to avoid this scenario.



Linedef types:

New Behaviour (> 2.2):
Linedef Executor - Call Lua Function (443): Write "P_Axis2D" (case-insensitive)
across the textures. The tag is the axis number to snap to. Call this
with a tag of 0 to exit Axis2D mode and go back to 3D.

-- Axis2D Options (443):

-- Tag: The tag is the axis number to use this with.
   
-- [5] EFFECT 1 (E1): The frontsector floor height will set the camera distance
    from the player (It defaults to 448 otherwise).
   
-- [6] No Climb: If checked, this is an absolute angle, otherwise it's relative
    to the normal camera angle.
   
-- [7] EFFECT 2 (E2): The backsector floor height will set the camera's height
    relative to the player.

-- [8] EFFECT 3 (E3): The x offset texture field of the lindef's frontside
    will determine the angle of the camera. The angle of the
    linedef is the camera angle by default when unchecked (in reverse).
    
-- [9] EFFECT 2 (E4): The y offset texture field of the lindef's frontside
    will determine if the camera aims either up or downwards using the player's
    aiming field.

Legacy Behaviour (Backwards Compatability):
Linedef Executor - Call Lua Function (443): Write "P_DoAngleSpin" (case-insensitive)
across the textures. (One way to do this is writing "P_DOANGL" in the upper texture
and "ESPIN" in the mid texture.) The tag is the axis number to snap to. Call this
with a tag of 0 to exit Axis2D mode and go back to 3D.

Axis2D Switch Sector (9001): Use this like an invisible, intangible FOF. X offset is
the axis number to switch to. (A simpler method of axis switching than the linedef
executor method.) Does nothing if not already in Axis2D mode.

Axis2D Options (9000): The tag is the axis number to use this with. The angle of the
linedef is the camera angle (in reverse); if No Climb is checked, this is an absolute
angle, otherwise it's relative to the normal camera angle. If Effect 1 is checked,
then the linedef's length will determine the camera distance from the player. (It
defaults to 448 otherwise, so design your geometry around that.)



Issues: Due to Axis2D not accounting for 'Simple Mode' as it was not included during
development, players will thok backwards when using the charability CA_THOK.
This will be addressed in the future.



Special notes:

The current release does not make spilled rings execute Axis2D-related linedef
executors. If you used an older version and need this functionality back, set
axis2d.legacymode = true in the script.

If legacy mode is enabled, spilled rings can execute any linedef trigger that
contains a trigger to switch axes. This is so they stay on the level track. Be
careful with your linedef setup and try to keep triggers to only switching axes or
only doing other things.

Axis2D must never be on at the same time as vanilla 2D. Movement will have issues
otherwise. Make sure to always set the player into 3D mode if you're transitioning
between vanilla 2D and Axis2D, and DO NOT set the 2D typeoflevel in your level's
header.

Be careful to always place triggers to enter Axis2D axes at and around starposts, or
the player may unintentionally respawn into 3D.



Have fun! If this readme doesn't do a great job at explaining things, ask sprki_zard (Varren)
on the MB, Discord, or through any other means of contact!
