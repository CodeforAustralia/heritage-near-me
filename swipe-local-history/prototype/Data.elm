module Data (fetch, map, defaultMap, getItem) where

import Json.Decode as Json exposing ((:=), andThen)
import Date exposing (Date)
import Dict exposing (Dict)
import Task exposing (Task)
import Http

import Types exposing (..)
import Story

url : String -> String
url subUrl = Http.url ("api/"++subUrl) []

fetch : App StoryId Story -> Task () (Action StoryId Story)
fetch app = case app.location of
    Discovering ->
        if isLoaded app.discovery.item then
            Task.succeed NoAction
        else
            Task.map (LoadItems << Succeeded) fetchDiscoverStories
            `Task.onError`
                (Task.succeed << LoadItems << Failed)
    Viewing storyId ->
        if (isLoaded <| getItem app storyId) && (not <| isLoaded <| findItem app (\story -> Story.id story == storyId && isDiscoverStory story)) then
            Task.succeed NoAction
        else
            Task.map (LoadItem storyId << Succeeded) (fetchFullStory storyId)
            `Task.onError`
                (Task.succeed << LoadItem storyId << Failed)
    _ -> Task.succeed NoAction

fetchDiscoverStories : Task Http.Error (List Story)
fetchDiscoverStories = Http.get discoverStories <| url "story_discover"

discoverStories : Json.Decoder (List Story)
discoverStories = Json.list discoverStory

discoverStory : Json.Decoder Story
discoverStory = Json.object4
    (\id title blurb photo -> DiscoverStory
        { id = StoryId id
        , title = title
        , blurb = blurb
        , photo = photo
        })
    ("id" := Json.int)
    ("title" := Json.string)
    ("blurb" := Json.string)
    ("photo" := Json.oneOf [Json.string, Json.null ""])

fetchFullStory : StoryId -> Task Http.Error Story
fetchFullStory storyId = let
        (StoryId id) = storyId
    in
        (Task.map List.head
        <| Http.get fullStories
        <| Http.url (url "story_details") [("id", "eq." ++ toString id)])
        `Task.andThen`
            (\storyId -> Maybe.withDefault
            (Task.fail <| Http.BadResponse 404 "Story with given id was not found")
            <| Maybe.map Task.succeed storyId)

fullStories : Json.Decoder (List Story)
fullStories = Json.list fullStory

fullStory : Json.Decoder Story
fullStory = ("id" := Json.int) `andThen` \id -> Json.object8
    (\title blurb suburb dates photos story sites locations -> FullStory
        { id = StoryId id
        , title = title
        , blurb = blurb
        , suburb = suburb
        , dates = dates
        , photos = photos
        , story = story
        , sites = List.filterMap identity sites
        , locations = List.filterMap identity locations
        })
    ("title" := Json.string)
    ("blurb" := Json.string)
    (Json.maybe ("suburb" := Json.string))
    ("dates" := dates)
    ("photos" := Json.list (Json.oneOf [Json.string, Json.null ""]))
    ("story" := Json.string)
    ("sites" := Json.list (Json.maybe site))
    ("locations" := Json.list (Json.maybe location))

dates : Json.Decoder Dates
dates = Json.object2
    (\start end ->
        { start = start `Maybe.andThen` (Date.fromString >> Result.toMaybe)
        , end = end `Maybe.andThen` (Date.fromString >> Result.toMaybe)
        })
    (Json.maybe ("start" := Json.string))
    (Json.maybe ("end" := Json.string))

site : Json.Decoder Site
site = Json.object2
    (\id name -> {id = id, name = name})
    ("id" := Json.string)
    ("name" := Json.string)

location : Json.Decoder LatLng
location = Json.object2
    (\lat lng -> {lat = lat, lng = lng})
    ("lat" := Json.string)
    ("lng" := Json.string)

isDiscoverStory : Story -> Bool
isDiscoverStory story = case story of
    DiscoverStory story -> True
    FullStory story -> False

isFullStory : Story -> Bool
isFullStory story = case story of
    DiscoverStory story -> False
    FullStory story -> True

isLoaded : RemoteData a -> Bool
isLoaded data = case data of
    Loaded _ -> True
    _ -> False

map : (a -> b) -> RemoteData a -> RemoteData b
map f data = case data of
    Loaded (Succeeded x) -> Loaded <| Succeeded <| f x
    Loaded (Failed x) -> Loaded <| Failed x
    Loading -> Loading

defaultMap : b -> (a -> b) -> RemoteData a -> b
defaultMap default f data = case data of
    Loaded (Succeeded x) -> f x
    _ -> default

getItem : App id a -> id -> RemoteData a
getItem app id = Maybe.withDefault Loading
    <| Dict.get (toString id) app.items

findItem : App id a -> (a -> Bool) -> RemoteData a
findItem app check = Maybe.withDefault Loading
    <| List.head
    <| List.filter (defaultMap False check)
    <| Dict.values app.items
