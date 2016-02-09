import Html exposing (Html, div, nav, h1, button, i, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Swipe exposing (SwipeState)
import Task exposing (Task)
import Dict exposing (Dict)
import Effects
import History
import RouteHash
import StartApp

import Types exposing (..)
import Route
import Data
import Discover
import Story
import Favourites
import Swiping

main = app.html

app = StartApp.start
    { init = (initialApp, Effects.none)
    , view = view
    , update = \action model -> (update action model, effects action model)
    , inputs = [history.signal, data.signal]
    }

effects : Action id a -> App id a -> Effects.Effects (Action id a)
effects action app = case action of
    Back -> Effects.map (\_ -> NoAction) <| Debug.log "back" <| Effects.task History.back
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

data : Signal.Mailbox (Action StoryId Story)
data = Signal.mailbox NoAction

port fetchData : Signal (Task () ())
port fetchData = Signal.map Data.fetch app.model
    |> Signal.map (\fetch -> fetch `Task.andThen` (Signal.send data.address))

view : Signal.Address (Action StoryId Story) -> App StoryId Story -> Html
view address app = case app.location of
    Discovering -> Discover.view address app
        <| navigation app.location address
    Viewing storyId   -> div [class "app"]
        [ navigation app.location address
        , Story.view address <| getStory app storyId
        ]
    ViewingFavourites -> div [class "app"]
        [ navigation app.location address
        , Favourites.view address
            <| List.filterMap (\id -> Data.defaultMap Nothing Just <| getStory app id) app.discovery.favourites
        ]

navigation location address = nav [class "navigation"]
    [ case location of
        Discovering ->
            button [onClick address ViewFavourites] [i [class "fa fa-heart fa-3x"] []]
        Viewing _ ->
            button [onClick address Back] [i [class "fa fa-angle-left fa-5x"] []]
        ViewingFavourites ->
            button [onClick address Discover] [i [class "fa fa-map fa-3x"] []]
    , h1 [] [text "Heritage Near Me"]
    ]

update : Action StoryId Story -> App StoryId Story -> App StoryId Story
update action app = case app.location of
    Discovering ->
        case action of
            Discover        -> {app | location = Discovering}
            View story'     -> {app | location = Viewing story'}
            ViewFavourites  -> {app | location = ViewingFavourites}
            Favourite       -> {app | location = Discovering, discovery = favouriteItem app.discovery}
            Pass            -> {app | location = Discovering, discovery = passItem app.discovery}
            SwipingItem s   -> {app | discovery = swipeItem app.discovery s}
            LoadItem item   -> {app | items = addItem Story.id item app.items}
            LoadItems items -> {app | items = addItems Story.id items app.items, discovery = loadItems app.discovery items Story.id}
            _               -> app

    Viewing story ->
        case action of
            Discover        -> {app | location = Discovering}
            View story'     -> {app | location = Viewing story'}
            ViewFavourites  -> {app | location = ViewingFavourites}
            LoadItem item   -> {app | items = addItem Story.id item app.items}
            LoadItems items -> {app | items = addItems Story.id items app.items, discovery = loadItems app.discovery items Story.id}
            _               -> app

    ViewingFavourites ->
        case action of
            Discover        -> {app | location = Discovering}
            View story'     -> {app | location = Viewing story'}
            ViewFavourites  -> {app | location = ViewingFavourites}
            LoadItem item   -> {app | items = addItem Story.id item app.items}
            LoadItems items -> {app | items = addItems Story.id items app.items, discovery = loadItems app.discovery items Story.id}
            _               -> app

favouriteItem : Discovery id -> Discovery id
favouriteItem app =
    { app |
      item = Loaded <| Succeeded <| List.head app.items
    , items = (Maybe.withDefault [] << List.tail) app.items
    , favourites = case app.item of
        Loaded (Succeeded (Just item)) -> app.favourites ++ [item]
        _ -> app.favourites
    , swipeState = Nothing
    }

passItem : Discovery a -> Discovery a
passItem app =
    { app |
      item = Loaded <| Succeeded <| List.head app.items
    , items = (Maybe.withDefault [] << List.tail) app.items
    , passes = case app.item of
        Loaded (Succeeded (Just item)) -> app.passes ++ [item]
        _ -> app.passes
    , swipeState = Nothing
    }

swipeItem : Discovery a -> Maybe SwipeState -> Discovery a
swipeItem app state = {app | swipeState = state}

loadItems : Discovery id -> LoadedData (List a) -> (a -> id) -> Discovery id
loadItems discovery items getId = let
        ids = Data.defaultMap [] (List.map getId) <| Loaded items
    in
        {discovery |
          items = (Maybe.withDefault [] << List.tail) ids
        , item = Loaded <| Succeeded <| List.head ids
        }

addItems : (a -> id) -> LoadedData (List a) -> Dict String (RemoteData a) -> Dict String (RemoteData a)
addItems getId loaded items = case loaded of
    Succeeded loadedItems -> List.foldl
        (\loadedItem items -> Dict.insert
            (toString <| getId loadedItem)
            (Loaded <| Succeeded <| loadedItem)
            items)
        items
        loadedItems
    _ -> items

addItem : (a -> id) -> LoadedData a -> Dict String (RemoteData a) -> Dict String (RemoteData a)
addItem getId loaded items = case loaded of
    Succeeded item -> Dict.insert (toString <| getId item) (Loaded <| Succeeded <| item) items
    _ -> items

getStory : App StoryId Story -> StoryId -> RemoteData Story
getStory app = Data.getItem app

initialApp : App StoryId Story
initialApp = {location = Discovering, discovery = initialDiscovery, items = Dict.empty}

initialDiscovery =
    { item = Loading
    , items = []
    , favourites = []
    , passes = []
    , swipeState = Nothing
    }
