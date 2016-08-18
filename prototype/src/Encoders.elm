module Encoders (remoteFullStoriesMapEncoder) where

{-| JSON encoders.

Might be useful for sending Elm records to JavaScript land through ports, for example.
-}

import Json.Encode

import Types exposing (..)
import Story
import Remote.DataStore exposing (RemoteDataStore)



{-| encode the parts of the story we need to pass through to JS map -}
remoteFullStoriesMapEncoder : RemoteDataStore StoryId Story -> Json.Encode.Value
remoteFullStoriesMapEncoder items =
    let
        stories = Remote.DataStore.loaded items
        fullStories = takeFullStories stories
    in
        fullStoriesMapEncoder fullStories


--remoteStoriesMapEncoder : RemoteDataStore StoryId Story -> Json.Encode.Value
--remoteStoriesMapEncoder items =
--    let
--        stories = Remote.DataStore.loaded items
--        --fullStories = takeFullStories stories
--    in
--        allStoriesMapEncoder stories


fullStoriesMapEncoder : List Story -> Json.Encode.Value
fullStoriesMapEncoder stories =
    let
        listOfValues = List.map fullStoryMapEncoder stories
    in
        Json.Encode.list listOfValues


--allStoriesMapEncoder : List Story -> Json.Encode.Value
--allStoriesMapEncoder stories =
--    let
--        listOfValues = List.map storyMapEncoder stories
--    in
--        Json.Encode.list listOfValues


{-| Encodes just some fields [1] from just some stories [2].
1: We just want fields like lat/long a site name, and
photo url, to provide story summary in popup marker.

2: We only want to output full stories, since those have lat/long that we need.
-}
fullStoryMapEncoder : Story -> Json.Encode.Value
fullStoryMapEncoder story =
    case story of

        DiscoverStory s ->
            Json.Encode.object
                [ ("error", Json.Encode.string "was not expecting discover story") ]

        FullStory s ->
            Json.Encode.object
                [ ("storyId", Json.Encode.string <| Story.storyIdToStr s.id)
                , ("photoUrl", stringOrNullEncoder <| List.head s.photos)
                , ("distance", floatOrNullEncoder s.distance)
                , ("firstLocation", latLngOrNullEncoder <| List.head s.locations)
                , ("firstSiteName", Json.Encode.string <| siteNameOrDefault <| List.head s.sites)
                ]


{-| Encodes just some fields [1].
1: We just want fields like lat/long a site name, and
photo url, to provide story summary in popup marker.
-}
--storyMapEncoder : Story -> Json.Encode.Value
--storyMapEncoder story =
--    case story of

--        DiscoverStory s ->
--            Json.Encode.object
--                [ ("storyId", Json.Encode.string <| Story.storyIdToStr s.id)
--                , ("photoUrl", Json.Encode.string s.photo)
--                , ("distance", floatOrNullEncoder s.distance)
--                , ("firstLocation", latLngOrNullEncoder <| List.head s.locations)
--                , ("firstSiteName", Json.Encode.string <| siteNameOrDefault <| List.head s.sites)
--                ]

--        FullStory s ->
--            Json.Encode.object
--                [ ("storyId", Json.Encode.string <| Story.storyIdToStr s.id)
--                , ("photoUrl", stringOrNullEncoder <| List.head s.photos)
--                , ("distance", floatOrNullEncoder s.distance)
--                , ("firstLocation", latLngOrNullEncoder <| List.head s.locations)
--                , ("firstSiteName", Json.Encode.string <| siteNameOrDefault <| List.head s.sites)
--                ]


siteNameOrDefault : Maybe Site -> String
siteNameOrDefault site =
    case site of
        Just site -> site.name
        Nothing -> "No known sites"


latLngEncoder : LatLng -> Json.Encode.Value
latLngEncoder latlng =
    Json.Encode.object
        [ ("lat", Json.Encode.string latlng.lat)
        , ("lng", Json.Encode.string latlng.lng)
        ]

latLngOrNullEncoder : Maybe LatLng -> Json.Encode.Value
latLngOrNullEncoder val = maybeEncoder val latLngEncoder

stringOrNullEncoder : Maybe String -> Json.Encode.Value
stringOrNullEncoder val = maybeEncoder val Json.Encode.string

floatOrNullEncoder : Maybe Float -> Json.Encode.Value
floatOrNullEncoder val = maybeEncoder val Json.Encode.float

maybeEncoder : Maybe a -> (a -> Json.Encode.Value) -> Json.Encode.Value
maybeEncoder val encoder =
    case val of
        Just val -> encoder val
        Nothing -> Json.Encode.null


takeFullStories : List Story -> List Story
takeFullStories list = List.filter isFullStory list

isFullStory : Story -> Bool
isFullStory story =
    case story of
        FullStory s -> True
        _ -> False


