module Data (fetch, map) where

import Json.Decode as Json exposing ((:=))
import Task exposing (Task)
import Http

import Types exposing (..)

url : String -> String
url subUrl = Http.url ("http://localhost:3000/"++subUrl) []

fetch : App Story -> Task () (Action Story)
fetch app = case app.location of
    Discovering ->
        if isLoaded app.discovery.items then
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
discoverStory = Json.object2 (\title photo -> {title = title, photo=photo, story=""})
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
