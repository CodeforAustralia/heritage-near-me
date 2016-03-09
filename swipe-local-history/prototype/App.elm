import Html exposing (Html)
import Time exposing (Time)
import Task exposing (Task)
import Dict exposing (Dict)
import Json.Encode
import Json.Decode as Json exposing ((:=))
import Http
import Effects
import History
import RouteHash
import StartApp

import Types exposing (..)
import Remote.Data exposing (RemoteData(..))
import Remote.DataStore exposing (RemoteDataStore)
import Route
import Data
import View exposing (view)
import Story
import Favourites
import Swiping

main : Signal Html
main = app.html

app = StartApp.start
    { init = (initialApp, Effects.none)
    , view = view
    , update = \action model -> (update action model, effects action model)
    , inputs = [history.signal, Swiping.animate, userLocation]
    }

effects : Action StoryId Story -> App StoryId Story -> Effects.Effects (Action StoryId Story)
effects action app = case action of
    View storyId -> Effects.task
        <| Task.map LoadData
        <| Remote.DataStore.fetchInsert storyId Data.requestStory
    UpdateLocation loc ->
        if app.discovery == initialDiscovery then
            case loc of
                Just latlng -> fetchDiscover <| Data.requestNearbyStories latlng
                Nothing -> fetchDiscover <| Data.requestStories
        else
            Effects.none
    Back -> Effects.map (\_ -> NoAction) <| Effects.task History.back
    Animate time window -> case app.location of
        Viewing _ view -> case view.photoPosition of
            Leaving window pos start end _ ->
                if time > end then
                    Effects.task <| Task.succeed
                    <| if pos < 0 then
                        NextPhoto
                    else if pos > 0 then
                        PrevPhoto 
                    else
                        NoAction
                else
                    Effects.none
            _ -> Effects.none
        Discovering -> case app.discovery.itemPosition of
            Leaving window pos start end _ ->
                if time > end then
                    Effects.task <| Task.succeed
                    <| if pos < 0 then
                        Pass
                    else if pos > 0 then
                        Favourite
                    else
                        NoAction
                else
                    Effects.none
            _ -> Effects.none
        _ -> Effects.none
    _ -> Effects.none

port tasks : Signal (Task.Task Effects.Never ())
port tasks = app.tasks

{-| Location from browser -}
port geolocation : Signal Json.Encode.Value

{-| Signal with Actions to update the user's location.
If `Nothing` then the user has disallowed geolocation.
-}
userLocation : Signal (Action id a)
userLocation = Signal.map (UpdateLocation << Result.toMaybe << Json.decodeValue latLng) geolocation

{-| Latitude/Longitude JSON decoder -}
latLng : Json.Decoder LatLng
latLng = Json.object2 (\lat lng -> {lat = toString lat, lng = toString lng})
        ("lat" := Json.float)
        ("lng" := Json.float)

history : Signal.Mailbox (Action StoryId Story)
history = Signal.mailbox NoAction

port routeTasks : Signal (Task () ())
port routeTasks = RouteHash.start
    { prefix = RouteHash.defaultPrefix
    , address = history.address
    , models = app.model
    , delta2update = Route.url
    , location2action = Route.action
    }

{- This function updates the state of the app
based on the given action and previous state of the app
-}
update : Action id a -> App id a -> App id a
update action app = case (app.location, action) of
    -- Discovering location Actions
    (Discovering, Animate time window)        -> {app | discovery = animateItem app.discovery time window}
    (Discovering, MoveItem pos)               -> {app | discovery = moveItem app.discovery pos}
    (Discovering, Favourite)                  -> {app | location = Discovering, discovery = favouriteItem app.discovery}
    (Discovering, Pass)                       -> {app | location = Discovering, discovery = passItem app.discovery}
    -- Viewing location actions
    (Viewing item view, Animate time window)  -> {app | location = Viewing item {view | photoPosition = Swiping.animateStep time window view.photoPosition}}
    (Viewing item view, MovePhoto pos)        -> {app | location = Viewing item {view | photoPosition = pos}}
    (Viewing item view, PrevPhoto)            -> {app | location = Viewing item {view | photoIndex = view.photoIndex-1, photoPosition = Static}}
    (Viewing item view, NextPhoto)            -> {app | location = Viewing item {view | photoIndex = view.photoIndex+1, photoPosition = Static}}
    (Viewing item view, JumpPhoto index)      -> {app | location = Viewing item {view | photoIndex = index, photoPosition = Static}}
    -- Location change actions
    (_, Discover)                             -> {app | location = Discovering}
    (_, View story')                          -> {app | location = Viewing story' initialItemView}
    (_, ViewFavourites)                       -> {app | location = ViewingFavourites}
    -- Data update actions
    (_, LoadData update)                      -> {app | items = update app.items}
    (_, LoadDiscoveryData items update)       -> {app | items = update app.items, discovery = updateDiscoverableItems app.discovery items}
    -- Do nothing for the rest of the actions
    (_, _)                                    -> app

favouriteItem : Discovery a -> Discovery a
favouriteItem app =
    { app |
      item = Loaded <| List.head app.items
    , items = (Maybe.withDefault [] << List.tail) app.items
    , favourites = case app.item of
        Loaded (Just item) -> app.favourites ++ [item]
        _ -> app.favourites
    , itemPosition = Static
    }

passItem : Discovery a -> Discovery a
passItem app =
    { app |
      item = Loaded <| List.head app.items
    , items = (Maybe.withDefault [] << List.tail) app.items
    , passes = case app.item of
        Loaded (Just item) -> app.passes ++ [item]
        _ -> app.passes
    , itemPosition = Static
    }

animateItem : Discovery a -> Time -> Window -> Discovery a
animateItem discovery time window = {discovery | itemPosition = Swiping.animateStep time window discovery.itemPosition}

moveItem : Discovery a -> ItemPosition -> Discovery a
moveItem discovery pos = {discovery | itemPosition = pos}

updateDiscoverableItems : Discovery id -> RemoteData (List id) -> Discovery id
updateDiscoverableItems discovery items =
    if discovery == initialDiscovery then
        { discovery |
          item = Remote.Data.map List.head items 
        , items = Remote.Data.get items |> Maybe.withDefault []
        }
    else
        discovery

fetchDiscover : Task Http.Error (List Story) -> Effects.Effects (Action StoryId Story)
fetchDiscover request = let
        update story = Remote.DataStore.update (Story.id story) (\old -> Just <| Loaded story)
    in
        Effects.task
            <| request
            `Task.andThen`
                (\stories ->
                    (\store -> List.foldl update store stories)
                    |> LoadDiscoveryData (Loaded <| List.map Story.id stories)
                    |> Task.succeed)
            `Task.onError`
                (\error -> LoadDiscoveryData (Failed error) identity |> Task.succeed)


initialApp : App StoryId Story
initialApp = {location = Discovering, discovery = initialDiscovery, items = Remote.DataStore.empty}

initialItemView : ItemView
initialItemView = {photoIndex = 0, photoPosition = Static}

initialDiscovery =
    { item = Loading
    , itemPosition = Static
    , items = []
    , favourites = []
    , passes = []
    }
