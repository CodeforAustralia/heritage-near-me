module Data (fetch, map, defaultMap, getItem) where

import Json.Decode as Json exposing ((:=))
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
    _ -> Task.succeed NoAction

fetchDiscoverStories : Task Http.Error (List Story)
fetchDiscoverStories = Http.get discoverStories <| url "story_discover"

discoverStories : Json.Decoder (List Story)
discoverStories = Json.list discoverStory

discoverStory : Json.Decoder Story
discoverStory = Json.object3
    (\id title photo -> {id = StoryId id, title = title, photo = photo, story = ""})
    ("id" := Json.int)
    ("title" := Json.string)
    ("photo" := Json.string)

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

getItem : App id a -> (a -> id) -> id -> RemoteData a
getItem app getId id = Maybe.withDefault Loading
    <| List.head
    <| List.filter (defaultMap False (\item -> getId item == id)) app.items
