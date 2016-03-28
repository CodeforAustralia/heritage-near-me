module Data (requestNearbyStories, requestStories, requestStory, viewStory, favouriteStory, getItem, updateStory) where

import Json.Decode as Json exposing ((:=), andThen)
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
discoverStory = Json.object5
    (\id title blurb photo distance -> DiscoverStory
        { id = StoryId id
        , title = Maybe.withDefault "" title
        , blurb = Maybe.withDefault "" blurb
        , photo = photo
        , distance = distance
        })
    ("id" := Json.int)
    (Json.maybe ("title" := Json.string))
    (Json.maybe ("blurb" := Json.string))
    ("photo" := Json.oneOf [Json.string, Json.null "images/unavailable.jpg"])
    (Json.maybe ("distance" := Json.float))

{- List of Stories JSON Decoder -}
fullStories : Json.Decoder (List Story)
fullStories = Json.list fullStory

{-| Story JSON decoder

Note that we have to chain several decoder funtions
-}
fullStory : Json.Decoder Story
fullStory =
    (Json.maybe ("title" := Json.string)) `andThen` \title ->
    (Json.maybe ("blurb" := Json.string)) `andThen` \blurb ->
    (Json.maybe ("suburb" := Json.string)) `andThen` \suburb ->
    (Json.maybe ("story" := Json.string)) `andThen` \story ->
    (Json.maybe ("author" := Json.string)) `andThen` \author ->
    (Json.maybe ("dates" := dates)) `andThen` \dates ->
    ("photos" := Json.list (Json.oneOf [Json.string, Json.null "images/unavailable.jpg"])) `andThen` \photos ->
    ("sites" := Json.list site) `andThen` \sites ->
    ("locations" := Json.list location) `andThen` \locations ->
    ("links" := Json.list link) `andThen` \links ->
    Json.object1
    (\id -> FullStory
        { id = StoryId id
        , title = Maybe.withDefault "" title
        , blurb = Maybe.withDefault "" blurb
        , suburb = suburb
        , story = Maybe.withDefault "This story hasn't been written yet!" story
        , author = author
        , dates = Maybe.withDefault {start = Nothing, end = Nothing} dates
        , photos = photos
        , sites = List.filterMap identity sites
        , locations = List.filterMap identity locations
        , links = links
        })
    ("id" := Json.int)

{-| Dates JSON decoder -}
dates : Json.Decoder Dates
dates = Json.object2
    (\start end ->
        { start = start `Maybe.andThen` (Date.fromString >> Result.toMaybe)
        , end = end `Maybe.andThen` (Date.fromString >> Result.toMaybe)
        })
    (Json.maybe ("start" := Json.string))
    (Json.maybe ("end" := Json.string))

{-| Site JSON decoder -}
site : Json.Decoder (Maybe Site)
site = Json.object2
    (Maybe.map2 (\id name -> {id = id, name = name}))
    (Json.maybe ("id" := Json.string))
    (Json.maybe ("name" := Json.string))

{-| Location JSON decoder -}
location : Json.Decoder (Maybe LatLng)
location = Json.object2
    (Maybe.map2 (\lat lng -> {lat = lat, lng = lng}))
    (Json.maybe ("lat" := Json.string))
    (Json.maybe ("lng" := Json.string))

{-| Link JSON decoder -}
link : Json.Decoder Link
link = Json.object2
    (\url label -> {url = Maybe.withDefault "" url, label = Maybe.withDefault "" <| Maybe.oneOf [label, url]})
    (Json.maybe ("url" := Json.string))
    (Json.maybe ("label" := Json.string))
