module Data (requestNearbyStories, requestStories, requestStory, viewStory, favouriteStory, getItem, updateStory) where

import Json.Decode as Json exposing ((:=), andThen)
import Json.Decode.Extra exposing ((|:))
import Date.Format
import Date.Config.Config_en_au as AuDate
import Time exposing (Time)
import Date exposing (Date)
import Dict exposing (Dict)
import Task exposing (Task)
import Effects exposing (Effects, Never)
import Http

import Types exposing (..)
import Remote.Data exposing (RemoteData(..))
import Remote.DataStore
import Story

import Native.TimeTask

{-| A function to retrieve an item from the app's data store -}
getItem : id -> App id a -> RemoteData a
getItem id app = Remote.DataStore.get id app.items

{-| A function to update a story in the data store -}
updateStory : RemoteData Story -> Maybe (RemoteData Story) -> Maybe (RemoteData Story)
updateStory newStory oldStory = case (Remote.Data.get newStory, oldStory `Maybe.andThen` Remote.Data.get) of
            -- Only load full stories over the top of discover stories and not the other way around
            (Just newStory', Just oldStory') -> case (newStory', oldStory') of
                (FullStory story, _) -> Just <| Loaded <| FullStory <| story
                (DiscoverStory story, DiscoverStory _) -> Just <| Loaded <| DiscoverStory story
                _ -> oldStory
            _ -> Just newStory

{-| A function to create an API url from a given sub url -}
url : String -> String
url subUrl = Http.url ("api/"++subUrl) []

{-| Http Request for Discovery stories with distances from current location -}
requestNearbyStories : LatLng -> Task Http.Error (List Story)
requestNearbyStories pos = Http.send Http.defaultSettings
    { verb = "POST"
    , headers = [("Content-Type", "application/json")]
    , url = url "rpc/nearby_stories"
    , body = Http.string <| "{\"lat\": \""++pos.lat++"\", \"lng\": \""++pos.lng++"\"}"
    }
    |> Http.fromJson discoverStories

{-| Http Request for Discovery stories -}
requestStories : Task Http.Error (List Story)
requestStories = Http.get discoverStories <| url "story_discover"

{-| Http Request for a given Story Id -}
requestStory : StoryId -> Task Http.Error Story
requestStory storyId = let
        (StoryId id) = storyId
    in
        (Task.map List.head
        <| Http.get fullStories
        <| Http.url (url "story_details") [("id", "eq." ++ toString id)])
        `Task.andThen`
            (\storyId -> Maybe.withDefault
            (Task.fail <| Http.BadResponse 404 "Story with given id was not found")
            <| Maybe.map Task.succeed storyId)

{-| Http request to indicate a story is being viewed -}
viewStory : StoryId -> Task Never (Result Http.RawError Http.Response)
viewStory (StoryId story) = Native.TimeTask.getCurrentTime
    `Task.andThen` \time ->
        Http.send Http.defaultSettings
        { verb = "POST"
        , headers = [("Content-Type", "application/json")]
        , url = url "views"
        , body = Http.string <| "{\"datetime\": \""++timestamp time++"\", \"story_id\": \""++toString story++"\"}"
        }
    |> Task.toResult

{-| Http request to indicate a story is being viewed -}
favouriteStory : StoryId -> Bool -> Task Never (Result Http.RawError Http.Response)
favouriteStory (StoryId story) favourited = Native.TimeTask.getCurrentTime
    `Task.andThen` \time ->
        Http.send Http.defaultSettings
        { verb = "POST"
        , headers = [("Content-Type", "application/json")]
        , url = url "favourites"
        , body = Http.string <| "{\"datetime\": \""++timestamp time++"\", \"story_id\": \""++toString story++"\", \"favourited\": \""++toString favourited++"\"}"
        }
    |> Task.toResult

{-| Format a time as a postgres ISO timestamp -}
timestamp : Time -> String
timestamp time = 
    let
        isoFormat = "%Y-%m-%d %H:%M:%S"
        isoDatetime = (Date.Format.format AuDate.config isoFormat << Date.fromTime) time
    in
        "'" ++ isoDatetime ++ "'"

{-| List of Discover Stories JSON Decoder -}
discoverStories : Json.Decoder (List Story)
discoverStories = Json.list discoverStory

{-| Discover Story JSON decoder -}
discoverStory : Json.Decoder Story
discoverStory = Json.object6
    (\id title blurb photo distance sites -> DiscoverStory
        { id = StoryId id
        , title = Maybe.withDefault "" title
        , blurb = Maybe.withDefault "" blurb
        , photo = photo
        , distance = distance
        , sites = List.filterMap identity sites
        })
    ("id" := Json.int)
    (Json.maybe ("title" := Json.string))
    (Json.maybe ("blurb" := Json.string))
    ("photo" := Json.oneOf [Json.string, Json.null "images/unavailable.jpg"])
    (Json.maybe ("distance" := Json.float))
    ("sites" := Json.list siteDecoder)

{- List of Stories JSON Decoder -}
fullStories : Json.Decoder (List Story)
fullStories = Json.list fullStoryDecoder

{-| Story JSON decoder -}
fullStoryDecoder : Json.Decoder Story
fullStoryDecoder =
    Json.succeed
        (\id title blurb suburb story dates photos sites locations distance -> FullStory
            { id = StoryId id
            , title = Maybe.withDefault "" title
            , blurb = Maybe.withDefault "" blurb
            , suburb = suburb
            , dates = Maybe.withDefault {start = Nothing, end = Nothing} dates
            , photos = photos
            , story = story -- Maybe.withDefault "This story hasn't been written yet!" story
            , sites = List.filterMap identity sites
            , locations = List.filterMap identity locations
            , distance = distance
            })
        |: ("id" := Json.int)
        |: (Json.maybe ("title" := Json.string))
        |: (Json.maybe ("blurb" := Json.string))
        |: (Json.maybe ("suburb" := Json.string))
        |: ("story" := Json.oneOf [Json.string, Json.null "This story hasn't been written yet!"])
        |: (Json.maybe ("dates" := datesDecoder))
        |: ("photos" := Json.list (Json.oneOf [Json.string, Json.null "images/unavailable.jpg"]))
        |: ("sites" := Json.list siteDecoder)
        |: ("locations" := Json.list locationDecoder)
        |: (Json.maybe ("distance" := Json.float))


{-| Dates JSON decoder -}
datesDecoder : Json.Decoder Dates
datesDecoder = Json.object2
    (\start end ->
        { start = start `Maybe.andThen` (Date.fromString >> Result.toMaybe)
        , end = end `Maybe.andThen` (Date.fromString >> Result.toMaybe)
        })
    (Json.maybe ("start" := Json.string))
    (Json.maybe ("end" := Json.string))

{-| Site JSON decoder -}
siteDecoder : Json.Decoder (Maybe Site)
siteDecoder = Json.object2
    (Maybe.map2 (\id name -> {id = id, name = name}))
    (Json.maybe ("id" := Json.string))
    (Json.maybe ("name" := Json.string))

{-| Location JSON decoder -}
locationDecoder : Json.Decoder (Maybe LatLng)
locationDecoder = Json.object2
    (Maybe.map2 (\lat lng -> {lat = lat, lng = lng}))
    (Json.maybe ("lat" := Json.string))
    (Json.maybe ("lng" := Json.string))
