###
A model object which is a list of tracks. We follow the API of the Google 
Realtime API CollaborativeList object 
(https://developers.google.com/google-apps/realtime/reference/gapi.drive.realtime.CollaborativeList)
but separate the rest of prong from anything Google specific
###


class ProngList

    _members: []

    # takes bare objects and makes them into our Model objects
    constructor: (list) ->
        this._members = list.map (item) =>
            return new Map(track)
        


    asArray: =>
        return this._members

