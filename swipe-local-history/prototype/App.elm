import Html exposing (Html, div, nav, img, button, a, i, text)
import Html.Attributes exposing (class, src, href)
import Html.Events exposing (onClick)
import Time exposing (Time)
import Task exposing (Task)
import Dict exposing (Dict)
import Http
import Json.Encode
import Json.Decode as Json exposing ((:=))
import Effects
import History
import RouteHash
import StartApp

import Types exposing (..)
import Remote.Data exposing (RemoteData(..))
import Remote.DataStore exposing (RemoteDataStore)
import Route
import Data
import Discover
import Story
import Favourites
import Swiping

main : Signal Html
main = app.html

app = StartApp.start
    { init = (initialApp, Effects.none)
    , view = view
    , update = \action model -> (update action model, effects action model)
    , inputs = [history.signal, data.signal, Swiping.animate, userLocation]
    }

effects : Action StoryId Story -> App StoryId Story -> Effects.Effects (Action StoryId Story)
effects action app = case action of
    View storyId -> Effects.task
        <| Data.requestStory storyId
        `Task.andThen`
            (\value -> Remote.DataStore.update storyId (\old -> Just <| Loaded value) |> LoadData |> Task.succeed)
        `Task.onError`
            (\error -> Remote.DataStore.update storyId (\old -> Just <| Maybe.withDefault (Failed error) old) |> LoadData |> Task.succeed)
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

port geolocation : Signal Json.Encode.Value

latLng : Json.Decoder LatLng
latLng = Json.object2 (\lat lng -> {lat = toString lat, lng = toString lng})
        ("lat" := Json.float)
        ("lng" := Json.float)

userLocation : Signal (Action id item)
userLocation = Signal.map (UpdateLocation << Result.toMaybe << Json.decodeValue latLng) geolocation

data : Signal.Mailbox (Action StoryId Story)
data = Signal.mailbox NoAction

view : Signal.Address (Action StoryId Story) -> App StoryId Story -> Html
view address app = case app.location of
    Discovering -> Discover.view address app
        <| navigation app.location address
    Viewing storyId itemView -> div [class "app"]
        [ navigation app.location address
        , Story.view address (Data.getItem storyId app) itemView
        ]
    ViewingFavourites -> div [class "app"]
        [ navigation app.location address
        , Favourites.view address
            <| List.filterMap Remote.Data.get
            <| List.map (\id -> Data.getItem id app)
            <| app.discovery.favourites
        ]

navigation location address = nav [class "navigation"]
    [ case location of
        Discovering ->
            button [onClick address ViewFavourites] [i [class "fa fa-heart fa-2x"] []]
        Viewing _ _ ->
            button [onClick address Back] [i [class "fa fa-angle-left fa-3x"] []]
        ViewingFavourites ->
            button [onClick address Discover] [i [class "fa fa-map fa-2x"] []]
    , div [class "logo"] [a [href "/"] [img [src "images/logo.png"] []]]
    ]

update : Action StoryId Story -> App StoryId Story -> App StoryId Story
update action app = case app.location of
    Discovering ->
        case action of
            Discover            -> {app | location = Discovering}
            View story'         -> {app | location = Viewing story' initialItemView}
            ViewFavourites      -> {app | location = ViewingFavourites}
            Animate time window -> {app | discovery = animateItem app.discovery time window}
            MoveItem pos        -> {app | discovery = moveItem app.discovery pos}
            Favourite           -> {app | location = Discovering, discovery = favouriteItem app.discovery}
            Pass                -> {app | location = Discovering, discovery = passItem app.discovery}
            LoadData update     -> {app | items = update app.items}
            LoadDiscoveryData
                   items update -> {app | items = update app.items, discovery = updateDiscoverableItems app.discovery items}
            _                   -> app

    Viewing story view ->
        case action of
            Discover            -> {app | location = Discovering}
            View story'         -> {app | location = Viewing story' initialItemView}
            ViewFavourites      -> {app | location = ViewingFavourites}
            Animate time window -> {app | location = Viewing story {view | photoPosition = Swiping.animateStep time window view.photoPosition}}
            MovePhoto pos       -> {app | location = Viewing story {view | photoPosition = pos}}
            PrevPhoto           -> {app | location = Viewing story {view | photoIndex = view.photoIndex-1, photoPosition = Static}}
            NextPhoto           -> {app | location = Viewing story {view | photoIndex = view.photoIndex+1, photoPosition = Static}}
            JumpPhoto index     -> {app | location = Viewing story {view | photoIndex = index, photoPosition = Static}}
            LoadData update     -> {app | items = update app.items}
            _                   -> app

    ViewingFavourites ->
        case action of
            Discover         -> {app | location = Discovering}
            View story'      -> {app | location = Viewing story' initialItemView}
            ViewFavourites   -> {app | location = ViewingFavourites}
            LoadData update     -> {app | items = update app.items}
            _                -> app

favouriteItem : Discovery id -> Discovery id
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
fetchDiscover request = Effects.task
    <| request
    `Task.andThen`
        (\stories ->
            (\store -> List.foldl
                (\story store -> Remote.DataStore.update (Story.id story) (\old -> Just <| Loaded story) store)
                store
                stories)
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
