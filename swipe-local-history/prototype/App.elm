import Html exposing (Html, div, nav, button, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Swipe exposing (SwipeState)
import Task exposing (Task)
import Effects
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
    , update = \action model -> (update action model, Effects.none)
    , inputs = [history.signal, data.signal]
    }

history : Signal.Mailbox (Action Story)
history = Signal.mailbox NoAction

port routeTasks : Signal (Task () ())
port routeTasks = RouteHash.start
    { prefix = RouteHash.defaultPrefix
    , address = history.address
    , models = app.model
    , delta2update = Route.url
    , location2action = Route.action
    }

data : Signal.Mailbox (Action Story)
data = Signal.mailbox NoAction

port fetchData : Signal (Task () ())
port fetchData = Signal.map Data.fetch app.model
    |> Signal.map (\fetch -> fetch `Task.andThen` (Signal.send data.address))

view : Signal.Address (Action Story) -> App Story -> Html
view address app = div [class "app"]
    [ navigation address
    , case app.location of
        Discovering       -> Discover.view   address app.discovery
        Viewing story     -> Story.view      address story
        ViewingFavourites -> Favourites.view address app.discovery.favourites
    ]

navigation address = nav [class "navigation"]
    [ button [onClick address Discover] [text "discover"]
    , button [onClick address ViewFavourites] [text "favourites"]
    ]

update : Action Story -> App Story -> App Story
update action app = case app.location of
    Discovering ->
        case action of
            Discover        -> {app | location = Discovering}
            View story'     -> {app | location = Viewing story'}
            ViewFavourites  -> {app | location = ViewingFavourites}
            Favourite       -> {app | location = Discovering, discovery = favouriteItem app.discovery}
            Pass            -> {app | location = Discovering, discovery = passItem app.discovery}
            SwipingItem s   -> {app | discovery = swipeItem app.discovery s}
            LoadItems items -> {app | discovery = loadItems app.discovery items}
            _               -> app

    Viewing story ->
        case action of
            Discover        -> {app | location = Discovering}
            View story'     -> {app | location = Viewing story'}
            ViewFavourites  -> {app | location = ViewingFavourites}
            LoadItems items -> {app | discovery = loadItems app.discovery items}
            _               -> app

    ViewingFavourites ->
        case action of
            Discover        -> {app | location = Discovering}
            View story'     -> {app | location = Viewing story'}
            ViewFavourites  -> {app | location = ViewingFavourites}
            LoadItems items -> {app | discovery = loadItems app.discovery items}
            _               -> app

favouriteItem : Discovery a -> Discovery a
favouriteItem app =
    { app |
      item = Data.map List.head app.items
    , items = Data.map (Maybe.withDefault [] << List.tail) app.items
    , favourites = case app.item of
        Loaded (Succeeded (Just item)) -> app.favourites ++ [item]
        _ -> app.favourites
    , swipeState = Nothing
    }

passItem : Discovery a -> Discovery a
passItem app =
    { app |
      item = Data.map List.head app.items
    , items = Data.map (Maybe.withDefault [] << List.tail) app.items
    , passes = case app.item of
        Loaded (Succeeded (Just item)) -> app.passes ++ [item]
        _ -> app.passes
    , swipeState = Nothing
    }

swipeItem : Discovery a -> Maybe SwipeState -> Discovery a
swipeItem app state = {app | swipeState = state}

loadItems : Discovery a -> LoadedData (List a) -> Discovery a
loadItems discovery items = {discovery |
      items = Data.map (Maybe.withDefault [] << List.tail) <| Loaded items
    , item = Data.map List.head <| Loaded items
    }

initialApp : App Story
initialApp = {location = Discovering, discovery = initialDiscovery}

initialDiscovery =
    { item = Loading
    , items = Loading
    , favourites = []
    , passes = []
    , swipeState = Nothing
    }
