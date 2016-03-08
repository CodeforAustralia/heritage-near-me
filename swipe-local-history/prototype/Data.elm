module Data (requestStories, requestStory, getItem) where

import Json.Decode as Json exposing ((:=), andThen)
import Date exposing (Date)
import Dict exposing (Dict)
import Task exposing (Task)
import Effects exposing (Effects, Never)
import Http

import Types exposing (..)
import Remote.Data exposing (RemoteData)
import Remote.DataStore
import Story

getItem : id -> App id a -> RemoteData a
getItem id app = Remote.DataStore.get id app.items

url : String -> String
url subUrl = Http.url ("api/"++subUrl) []

requestStories : Task Http.Error (List Story)
requestStories = Http.get discoverStories <| url "story_discover"

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

discoverStories : Json.Decoder (List Story)
discoverStories = Json.list discoverStory

discoverStory : Json.Decoder Story
discoverStory = Json.object4
    (\id title blurb photo -> DiscoverStory
        { id = StoryId id
        , title = Maybe.withDefault "" title
        , blurb = Maybe.withDefault "" blurb
        , photo = photo
        })
    ("id" := Json.int)
    (Json.maybe ("title" := Json.string))
    (Json.maybe ("blurb" := Json.string))
    ("photo" := Json.oneOf [Json.string, Json.null ""])

fullStories : Json.Decoder (List Story)
fullStories = Json.list fullStory

fullStory : Json.Decoder Story
fullStory = ("id" := Json.int) `andThen` \id -> Json.object8
    (\title blurb suburb story dates photos sites locations -> FullStory
        { id = StoryId id
        , title = Maybe.withDefault "" title
        , blurb = Maybe.withDefault "" blurb
        , suburb = suburb
        , story = Maybe.withDefault "This story hasn't been written yet!" story
        , dates = Maybe.withDefault {start = Nothing, end = Nothing} dates
        , photos = photos
        , sites = List.filterMap identity sites
        , locations = List.filterMap identity locations
        })
    (Json.maybe ("title" := Json.string))
    (Json.maybe ("blurb" := Json.string))
    (Json.maybe ("suburb" := Json.string))
    (Json.maybe ("story" := Json.string))
    (Json.maybe ("dates" := dates))
    ("photos" := Json.list (Json.oneOf [Json.string, Json.null ""]))
    ("sites" := Json.list site)
    ("locations" := Json.list location)

dates : Json.Decoder Dates
dates = Json.object2
    (\start end ->
        { start = start `Maybe.andThen` (Date.fromString >> Result.toMaybe)
        , end = end `Maybe.andThen` (Date.fromString >> Result.toMaybe)
        })
    (Json.maybe ("start" := Json.string))
    (Json.maybe ("end" := Json.string))

site : Json.Decoder (Maybe Site)
site = Json.object2
    (Maybe.map2 (\id name -> {id = id, name = name}))
    (Json.maybe ("id" := Json.string))
    (Json.maybe ("name" := Json.string))

location : Json.Decoder (Maybe LatLng)
location = Json.object2
    (Maybe.map2 (\lat lng -> {lat = lat, lng = lng}))
    (Json.maybe ("lat" := Json.string))
    (Json.maybe ("lng" := Json.string))
