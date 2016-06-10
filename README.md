prong
=====

A collection of components to display and play DAW style
multi-track sequences of audio

Examples can be seen here http://forkaudio.org/prong/


sample usage
------------

    import prong from 'prong'

    // draw a 3 track sequence to the element with id 'sequence'

    var sequence = prong.sequence()
      .propertyPanelWidth(95)
      .width(705)
      .canSelectLoop(true)
      .trackHeight(50)
      .fitTimelineToAudio(false)
      .zoomable(true)
      .scrollable(true)
      .waveformVerticalZoom(1)
      .editable(true)
      .tracks([
        {
          type : 'audio',
          src : '/path/to/drums.mp3'
        },
        {
          type : 'audio',
          src : '/path/to/bass.mp3'
        },
        {
          type : 'audio',
          src : '/path/to/keys.mp3'
        }
      ])
      .audioOut(prong.audioContext().destination)
      .draw('#sequence')
