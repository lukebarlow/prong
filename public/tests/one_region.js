var root = 'https://dl.dropboxusercontent.com/u/5613860/audio/'

root = '/audio/'

var pool = [
    {
        "id": "whistling",
        "src": root + 'four_devices_computer.mp3'
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
    }
]