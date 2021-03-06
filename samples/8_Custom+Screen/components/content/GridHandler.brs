' ********** Copyright 2017 Roku Corp.  All Rights Reserved. **********

sub GetContent()
    ' url = CreateObject("roUrlTransfer")
    ' url.SetUrl("FEED_URL")
    ' url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ' url.AddHeader("X-Roku-Reserved-Dev-Id", "")
    ' url.InitClientCertificates()
    ' feed = url.GetToString()
    'this is for a sample, usually feed is retrieved from url using roUrlTransfer
    feed = ReadAsciiFile("pkg:/feed/feed.json")
    sleep(2000)

    json = ParseJson(feed)
    rootNodeArray = ParseJsonToNodeArray(json)
    m.top.content.AppendChildren(rootNodeArray)
end sub

function ParseJsonToNodeArray(jsonAA as Object) as Object
    if jsonAA = invalid then return []
    resultNodeArray = []

    for each fieldInJsonAA in jsonAA
        ' Assigning fields that apply to both movies and series
        if fieldInJsonAA = "movies" or fieldInJsonAA = "series"
            mediaItemsArray = jsonAA[fieldInJsonAA]
            itemsNodeArray = []
            for each mediaItem in mediaItemsArray
                itemNode = ParseMediaItemToNode(mediaItem, fieldInJsonAA)
                itemsNodeArray.Push(itemNode)
            end for
            rowNode = Utils_AAToContentNode({
                title: fieldInJsonAA
            })
            rowNode.AppendChildren(itemsNodeArray)

            resultNodeArray.Push(rowNode)
        end if
    end for

    return resultNodeArray
end function

function ParseMediaItemToNode(mediaItem as Object, mediaType as String) as Object
    itemNode = Utils_AAToContentNode({
            "id"    : mediaItem.id
            "title"    : mediaItem.title
            "hdPosterUrl" : mediaItem.thumbnail
            "Description" : mediaItem.shortDescription
            "Categories" : mediaItem.genres[0]
        })

    if mediaItem = invalid then
        return itemNode
    end if

    ' Assign movie specific fields
    if mediaType = "movies"
        Utils_forceSetFields(itemNode, {
            "Url": GetVideoUrl(mediaItem)
        })
    end if
    ' Assign series specific fields
    if mediaType = "series"
        seasons = mediaItem.seasons
        seasonArray = []
        for each season in seasons
            episodeArray = []
            episodes = season.Lookup("episodes")
            for each episode in episodes
                episodeNode = Utils_AAToContentNode(episode)
                Utils_forceSetFields(episodeNode, {
                    "url" : GetVideoUrl(episode)
                    "title" : episode.title
                    "hdPosterUrl" : episode.thumbnail
                    "Description" : episode.shortDescription
                })
                episodeArray.Push(episodeNode)
            end for
            seasonArray.Push(episodeArray)
        end for
        Utils_forceSetFields(itemNode, {
            "seasons": seasonArray
        })
    end if
    return itemNode
end function

function GetVideoUrl(mediaItem) as String
    content = mediaItem.Lookup("content")
    if content = invalid then
        return ""
    end if

    videos = content.Lookup("videos")
    if videos = invalid then
        return ""
    end if

    entry = videos.GetEntry(0)
    if entry = invalid then
        return ""
    end if

    url = entry.Lookup("url")
    if url = invalid then
        return ""
    end if

    return url
end function
