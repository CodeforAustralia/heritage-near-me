module Data (fetch, map, defaultMap, getItem) where

import Json.Decode as Json exposing ((:=))
import Dict exposing (Dict)
import Task exposing (Task)
import Http

import Types exposing (..)

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
        if isLoaded <| findItem app isFullStory then
            Task.succeed NoAction
        else
            Task.map (LoadItem << Succeeded) (fetchFullStory storyId)
            `Task.onError`
                (Task.succeed << LoadItem << Failed)
    _ -> Task.succeed NoAction

fetchDiscoverStories : Task Http.Error (List Story)
fetchDiscoverStories = Http.get discoverStories <| url "story_discover"

discoverStories : Json.Decoder (List Story)
discoverStories = Json.list discoverStory

discoverStory : Json.Decoder Story
discoverStory = Json.object3
    (\id title photo -> DiscoverStory {id = StoryId id, title = title, photo = photo})
    ("id" := Json.int)
    ("title" := Json.string)
    ("photo" := Json.string)

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
fullStory = Json.object4
    (\id title photos story -> FullStory {id = StoryId id, title = title, photos = photos, story = story})
    ("id" := Json.int)
    ("title" := Json.string)
    ("photos" := Json.list Json.string)
    ("story" := Json.string)

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
