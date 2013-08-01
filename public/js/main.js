function loadRemote(path, callback) {
    var fetch = new XMLHttpRequest();
    fetch.open('GET', path);
    fetch.overrideMimeType("text/plain; charset=x-user-defined");
    fetch.onreadystatechange = function() {
        if(this.readyState == 4 && this.status == 200) {
            /* munge response into a binary string */
            var t = this.responseText || "" ;
            var ff = [];
            var mx = t.length;
            var scc= String.fromCharCode;
            for (var z = 0; z < mx; z++) {
                ff[z] = scc(t.charCodeAt(z) & 255);
            }
            callback(ff.join(""));
        }
    }
    fetch.send();
}


// takes a midi track and returns just the note information, but organised
// into notes with absolute start and stop times. This is in contrast to
// the midi track which has separate note on and off events, and timings 
// recorded as deltas since the previous
function extractNoteObjects(midiTrack, colour){

    notes = []
    openNotes = {} // keep a record of noteOns that don't have noteOff yet
    time = 0

    midiTrack.forEach(function(event){

        time += event.deltaTime

        if (event.type != 'channel'){
            return
        }

        var key = event.channel + '.' + event.noteNumber

        switch(event.subtype){
            case 'noteOn' :
                var note = {}
                notes.push(note)
                note.noteNumber = event.noteNumber
                note.channel = event.channel
                note.startTime = time
                note.onVelocity = event.velocity
                note.colour = colour
                if (note.noteNumber in openNotes){
                    openNotes[key].push(note)
                }else{
                    openNotes[key] = [note]
                }
            break;
            case 'noteOff' :
                // if there are multiple overlapping notes on the same pitch,
                // then we follow a 'first on, first off' rule - copying Logic
                note = openNotes[key].shift()
                if (note){
                    note.duration = time - note.startTime
                    note.offVelocity = event.velocity
                }
                
            break;
        }
    })

    return notes

}

var x = d3.scale.linear().range([0,500]).domain([0,5000])
var y = d3.scale.linear().range([400,100]).domain([30,80])

function drawTrack(notes){

    var noteHeight = Math.abs(y(0) - y(1))

    d3.select('#sequence')
        .selectAll('rect')
        .data(notes)
        .enter()
        .append('rect')
        .attr('x', function(d){return x(d.startTime)})
        .attr('width', function(d){return x(d.duration)})
        .attr('y', function(d){return y(d.noteNumber)})
        .attr('height', noteHeight)
        .attr('fill', function(d){return d.colour})
}

function init(){
    loadRemote('/midi/minute_waltz.mid', function(data){
        var midiFile = MidiFile(data);
        var notes = extractNoteObjects(midiFile.tracks[1], 'red')
        notes.concat(extractNoteObjects(midiFile.tracks[2], 'blue'))

        var blue = extractNoteObjects(midiFile.tracks[2], 'blue')
        var red = extractNoteObjects(midiFile.tracks[1], 'red')
        var notes = blue.concat(red)
        drawTrack(notes)
    })
}