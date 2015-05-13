var root = 'https://dl.dropboxusercontent.com/u/5613860/audio/nino_rota_trimmed/'

root = '/audio/'

var pool = [
    {
        "id": "whistling",
        "src": root + 'four_devices_computer.mp3'
    },
    {
        "id": "snare",
        "src": root + 'snare.mp3'
    },
    {
        "id": "cymbals",
        "src": root + 'cymbals.mp3'
    },
    {
        "id": "bass_drum",
        "src": root + 'bass_drum.mp3'
    },
    {
        "id": "sax1",
        "src": root + 'sax1.mp3'
    }
]


var tracks = [
    {
        "name": "track 1",
        "type": "audioRegions",
        "regions": [
            {

                "clipId": "whistling",
                "clipStart": 0,
                "clipEnd": 10,
                "startTime": 4
            }
        ],
        "over": false,
        "pan": 0,
        "volume": 60
    },
    {
        "name": "track 2",
        "type": "audioRegions",
        "regions": [
            {

                "clipId": "whistling",
                "clipStart": 0,
                "clipEnd": 1,
                "startTime": 0
            },
            {

                "clipId": "whistling",
                "clipStart": 1,
                "clipEnd": 3,
                "startTime": 4
            }
        ],
        "over": false,
        "pan": 0,
        "volume": 60
    }
]