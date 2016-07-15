import Html exposing (Html)
import Time exposing (Time)
import Task exposing (Task)
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
import Swiping

-- Note: code below is documented with the Elm documentation format.
-- http://package.elm-lang.org/help/documentation-format

{-| The HTML view created by the app -}
main : Signal Html
main = app.html

{-| The app.
Consists of inputs, HTML views and functions which update and produce effects based on inputs.
-}
app : StartApp.App AppModel
app = StartApp.start
    { init = (initialApp, Effects.none)
    , view = view
    , update = update
    , inputs = [history.signal, Swiping.animate, userLocation]
    }

-- Get the next (model, action) pair based on the current action and model.
-- If it helps, note that an "action" is like a message ("do this action next") and, in fact,
-- is replaced in the next version of Elm, 0.17, with Messages ("Msg"):
-- https://github.com/elm-lang/elm-platform/blob/master/upgrade-docs/0.17.md#action-is-now-msg
update: AppAction -> AppModel -> (AppModel, Effects.Effects AppAction)
update action model = (updateModel action model, updateAction action model)

{- Run app tasks -}
port tasks : Signal (Task.Task Effects.Never ())
port tasks = app.tasks

{-| Interact with browser history -}
port routeTasks : Signal (Task () ())
port routeTasks = RouteHash.start
    { prefix = RouteHash.defaultPrefix
    , address = history.address
    , models = app.model
    , delta2update = Route.url
    , location2action = Route.action
    }

{-| Keep track of the effect of browser history on the app -}
history : Signal.Mailbox AppAction
history = Signal.mailbox NoAction

{-| Location from browser -}
port geolocation : Signal Json.Encode.Value

{-| Signal with Actions to update the user's location.
If `Nothing` then the user has disallowed geolocation.
-}
userLocation : Signal AppAction
userLocation = Signal.map (UpdateLocation << Result.toMaybe << Json.decodeValue latLng) geolocation

{-| Latitude/Longitude JSON decoder -}
latLng : Json.Decoder LatLng
latLng = Json.object2 (\lat lng -> {lat = toString lat, lng = toString lng})
        ("lat" := Json.float)
        ("lng" := Json.float)

{- This function updates the state of the app
based on the given action and previous state of the app
-}
updateModel : AppAction -> AppModel -> AppModel
updateModel action app = case (app.location, action) of
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

{- Perform effectful actions based on actions and app state -}
updateAction : AppAction -> AppModel -> Effects.Effects AppAction
updateAction action app = case action of
    View storyId -> Effects.task
        <| Task.map LoadData
        <| Data.viewStory storyId
        `Task.andThen` \_ -> Remote.DataStore.fetch storyId Data.requestStory Data.updateStory
    UpdateLocation loc ->
        if app.discovery == initialDiscovery then
            case loc of
                Just latlng -> fetchDiscover <| Data.requestNearbyStories latlng
                Nothing -> fetchDiscover <| Data.requestStories
        else
            Effects.none
    Favourite -> case app.discovery.item of
            (Loaded (Just storyId)) -> Effects.task
                <| Data.favouriteStory storyId True
                `Task.andThen` \_ -> Task.succeed NoAction
            _ -> Effects.none
    Pass -> case app.discovery.item of
            (Loaded (Just storyId)) -> Effects.task
                <| Data.favouriteStory storyId False
                `Task.andThen` \_ -> Task.succeed NoAction
            _ -> Effects.none
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

{-| Add a viewed item to the list of favourite items -}
favouriteItem : Discovery a -> Discovery a
favouriteItem app =
    { app |
      item = Loaded <| List.head app.items
    , items = Maybe.withDefault [] (List.tail app.items)
    , favourites = case app.item of
        Loaded (Just item) -> app.favourites ++ [item]
        _ -> app.favourites
    , itemPosition = Static
    }

{-| Add a viewed item to the list of passed items -}
passItem : Discovery a -> Discovery a
passItem app =
    { app |
      item = Loaded <| List.head app.items
    , items = Maybe.withDefault [] (List.tail app.items)
    , passes = case app.item of
        Loaded (Just item) -> app.passes ++ [item]
        _ -> app.passes
    , itemPosition = Static
    }

{-| Animate items being discovered -}
animateItem : Discovery a -> Time -> Window -> Discovery a
animateItem discovery time window = {discovery | itemPosition = Swiping.animateStep time window discovery.itemPosition}

{-| Move items that are swiped while being discovered -}
moveItem : Discovery a -> ItemPosition -> Discovery a
moveItem discovery pos = {discovery | itemPosition = pos}

{-| Update the app with new discovery stories -}
updateDiscoverableItems : Discovery id -> RemoteData (List id) -> Discovery id
updateDiscoverableItems discovery items =
    if discovery == initialDiscovery then
        { discovery |
          item = Remote.Data.map List.head items 
        , items = Remote.Data.get items |> Maybe.withDefault []
        }
    else
        discovery

{-| Take a HTTP request and create an action to update the app with new discovery stories -}
fetchDiscover : Task Http.Error (List Story) -> Effects.Effects AppAction
fetchDiscover request = let
        update story = Remote.DataStore.update (Story.id story) (Data.updateStory <| Loaded story)
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

{-| The initial state of the app -}
initialApp : AppModel
initialApp = {location = Discovering, discovery = initialDiscovery, items = Remote.DataStore.empty}

{-| The initial state of a singular item being viewed -}
initialItemView : ItemView
initialItemView = {photoIndex = 0, photoPosition = Static}

{-| The initial state of items being discovered -}
initialDiscovery : Discovery id
initialDiscovery =
    { item = Loading
    , itemPosition = Static
    , items = []
    , favourites = []
    , passes = []
    }
