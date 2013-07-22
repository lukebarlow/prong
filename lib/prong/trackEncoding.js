// two way conversion between editList arrays and a list of tracks

module.exports = {
    stringify : stringify, // convert from track list to string
    parse : parse // convert from string to list of tracks
}

function stringify(tracks){
      var t = tracks.map(function(track){
          return track.src + ',' + (track.startTime || 0) + ',' + 
                (track.volume != null ? track.volume : '0');
      }).join(';');
      return t
  }

function parse(s){

      console.log('in track parser')
      console.log(s)

      var tracks = [];
      if (!s) return tracks;
      var ids = s.split(';');
      ids.forEach(function(id){
          var b = id.split(',');
          var src = b[0];
          var startTime = b.length > 1 ? parseFloat(b[1]) : 0;
          var volume = b.length > 2 ? parseInt(b[2]) : 100;
          tracks.push(
              { 'type' : 'youtube',
                'src' : src,
                'startTime' : startTime,
                'volume' : volume
              }
          );
      });
      return tracks;
  }