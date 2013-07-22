/*
There is a single component which can handle multiple MIDI tracks. This can
smoothly transition between showing all those tracks grouped in the one piano
roll, or splitting them out so each track has it's own piano roll. The left
hand track selector gives you full control over this.


features
    - select notes. switch instrument
    - drag to move
    - alt drag to copy
    -

Want to notate pitch bends as actual bends in the visible note blocks. Obviously
you need to be able to tell the editor what the bend is for each note.

Also, might be nice to manipulate the various other controllers with different
widgety ways of manipulating shapes. For example:

    - loudness/volumne is done with hairpins, just like conventional notation. 
    Perhaps also try

Need a way to tune a chord, which goes across multiple instruments. The workflow
is something like
    - select a chord - hit a key to play that chord - move a note

look at guessing bar lines from MIDI data, so automatically notating
MIDI material that was not played to a click

Take the playing from those


*/


var pool = pool || {}
pool.midi = pool.midi || {}