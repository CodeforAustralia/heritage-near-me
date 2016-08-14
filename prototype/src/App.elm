{-| The main / primary / top level application file. Start here.

This file does a few important things:

1. defines an `update` function to transform from one state (model,action) to another, and

2. sets up inputs from the external world (browser geolocation, history, etc)
   that might influence future app states.

3. initializes the Elm app by way of `StartApp.start`, passing in the initial app model
   `initialApp`, the `update` and `view` functions, and the inputs.

See http://package.elm-lang.org/packages/evancz/start-app/2.0.0/StartApp for the general idea.

Some helper functions are included also.
-}

{- Side note:
If you aren't familiar with Elm, this is a comment;
see [Elm Syntax](http://elm-lang.org/docs/syntax#comments) to learn about that and more.
And note that comments with a vertical bar `{-| like this -}` are in [Elm documentation format](http://package.elm-lang.org/help/documentation-format).
-}

-- first let's import functions from some Elm library modules we'll need:
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

-- and let's import some of our custom types and functions we'll need:
import Types exposing (..)
import Remote.Data exposing (RemoteData(..))
import Remote.DataStore exposing (RemoteDataStore)
import Route
import Data
import View exposing (view)
import Story
import Swiping


{-| The initial state /model of the app

We start the app with a bunch of empty / default values in `initialApp` and `initialDiscovery`.
Give the file `Types.elm` a quick glance to familiarize yourself with
custom types we'll see here, like `AppModel` (top level model) and
`SplashPage` (a screen within the web app, in this parlance, a `Location`), seen used below.

-}
initialApp : AppModel -- an Elm type definition. In English: "initialApp is of type AppModel"
initialApp =
    { location = SplashPage,
      discovery = initialDiscovery,
      items = Remote.DataStore.empty,
      latLng = Nothing
    }

{-| The initial (empty) state of items being discovered -}
initialDiscovery : Discovery id
initialDiscovery =
    { item = Loading
    , itemPosition = Static
    , items = []
    , favourites = []
    , passes = []
    }


{-| Set up the app.

The app consists of inputs, HTML views and functions which update and produce effects based on inputs.

-}
app : StartApp.App AppModel
app = StartApp.start
    { init = (initialApp, viewSplash)
    , view = view
    , update = update
    --, inputs = [history.signal, userLocation]
    , inputs = [history.signal, Swiping.animate, userLocation]
    }

{-| The HTML view created by the app -}
main : Signal Html
main = app.html

viewSplash : Effects.Effects AppAction
viewSplash = effectAction ViewSplashPage

effectAction : AppAction -> Effects.Effects AppAction
effectAction action = Effects.task <| Task.succeed action

-----------------------------------------------  Set up some ports


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
userLocation = Signal.map (UpdateLocation << Result.toMaybe << Json.decodeValue latLngDecoder) (Debug.log "geo: " geolocation)

{-| Latitude/Longitude JSON decoder -}
latLngDecoder : Json.Decoder LatLng
latLngDecoder = Json.object2 (\lat lng -> Debug.log "attempting LatLng json decode" {lat = toString lat, lng = toString lng})
        ("lat" := Json.float)
        ("lng" := Json.float)



--------------------------------------------  update function & friends


{-| Update app state with the next (model, action) pair based on the current action and model.

If it helps, note that an "action" is like a message ("do this action next") and, in fact,
is replaced in the next version of Elm, 0.17, with Messages ("Msg"):
https://github.com/elm-lang/elm-platform/blob/master/upgrade-docs/0.17.md#action-is-now-msg

For example, if you first point your web browser to http://localhost/
(assuming you're developing locally), the `Route.action` function passed
into `RouteHash.start` will convert the URL into the default home
location, and produce the `SplashPage` action (as of this writing,
the home location is ViewSplashPage).  As a result, `update` is
first called with `action == ViewSplashPage` and `model == initialApp`.
In the `updateAction` function further down, you'd notice that there isn't anything
special to do in this case, and so we do nothing using Elm's underscore case which
catches everything not already caught:  `_ -> Effects.none`. At this point,
we're just sitting there with a spinning gif waiting for the user to let us
get their location. It isn't until the user allows or blocks sharing of location
that we'd get something we can work with:

```
    action == UpdateLocation (Just { lat = "-32.3223206", lng = "149.2251805" }),
    model  == initialApp
```

from there, the `updateModel` function does nothing but the `updateAction` function
uses the `Data.request...` functions to fetch stories from the API. Before long, the
`updateModel` function has it's turn:

```
    action == LoadDiscoveryData (Loaded ([StoryId 6,StoryId 17,StoryId 1,StoryId 20,...]))
    model == initialApp
```

and then somehow after that we're humming along.

By the way, you can see that for yourself by replacing `update action model = (...)` below
with:

```
    update action model = (updateModel (Debug.log "updateModel action:" action) (Debug.log "updateModel model:" model), updateAction (Debug.log "updateAction action:" action) (Debug.log "uA model:" model))
```

and viewing the console while starting the app.

-}
update: AppAction -> AppModel -> (AppModel, Effects.Effects AppAction)
update action model =
    let
        _ = Debug.log "update w/ model.location" model.location
        _ = Debug.log "update w/ action" action
    in
        (updateModel action model, updateAction action model)


{-| This function updates the state of the app based on the given action and previous state of the app
-}
updateModel : AppAction -> AppModel -> AppModel
updateModel action app = case (app.location, action) of
    -- Discovering location Actions
    --(Discovering, Animate time window)        -> {app}
    (Discovering, Animate time window)        -> {app | discovery = animateItem app.discovery time window}
    (Discovering, MoveItem pos)               -> {app | discovery = moveItem app.discovery pos}
    (Discovering, Favourite)                  -> {app | location = Discovering, discovery = favouriteItem app.discovery}
    (Discovering, Pass)                       -> {app | location = Discovering, discovery = passItem app.discovery}
    -- Viewing location actions
    (Viewing item view screen', Animate time window) -> {app | location = Viewing item {view | photoPosition = Swiping.animateStep time window view.photoPosition} screen'}
    (Viewing item view _ , MovePhoto pos)       -> {app | location = Viewing item {view | photoPosition = pos} screen1}
    (Viewing item view _ , PrevPhoto)           -> {app | location = Viewing item {view | photoIndex = view.photoIndex-1, photoPosition = Static} screen1}
    (Viewing item view _ , NextPhoto)           -> {app | location = Viewing item {view | photoIndex = view.photoIndex+1, photoPosition = Static} screen1}
    (Viewing item view _ , JumpPhoto index)     -> {app | location = Viewing item {view | photoIndex = index, photoPosition = Static} screen1}
    --(Viewing item view storyScreen, ViewBody)  -> {app | location = Viewing item view Body}
    --(Viewing item view storyScreen, ViewIntro) -> {app | location = Viewing item view Intro}
    -- Location change actions
    (_, Discover)                             -> {app | location = Discovering}
    --(_, View story')                          -> {app | location = Viewing story' initialItemView screen1}
    (_, View story' screen')                  -> {app | location = Viewing story' initialItemView screen'}
    (_, ViewFavourites)                       -> {app | location = ViewingFavourites}
    -- Data update actions
    (_, LoadData updateItems)                 -> {app | items = updateItems app.items}
    (_, LoadDiscoveryData items updateItems)  -> {app | items = updateItems app.items, discovery = updateDiscoverableItems app.discovery items}
    -- Geoposition update actions
    (_, UpdateLocation loc)                   -> {app | latLng = Debug.log "model setting GPS coords: " loc }
    -- Do nothing for the rest of the actions
    (_, _)                                    ->
        let
            _ = Debug.log "updateModel, no change for location" app.location
            _ = Debug.log "updateModel, no change for action  " action
        in
            app



{-| Perform effectful actions based on actions and app state -}
updateAction : AppAction -> AppModel -> Effects.Effects AppAction
updateAction action app = case action of
    ViewSplashPage -> Effects.task <| Task.sleep 3000 `Task.andThen` \_ -> Task.succeed <| Debug.log "Slept for a while, new action: " Discover
    View storyId _ ->
            -- sorry this case is long; if `let` is confusing, this might help:
            -- http://www.lambdacat.com/road-to-elm-let-and-in/
        let
            requestRemoteStory : StoryId -> Task Http.Error Story
            requestRemoteStory =
                case app.latLng of
                    Just ll ->
                        -- ask server to include story's distance from us
                        Data.requestNearbyStory ll
                    Nothing ->
                        -- fine! I don't really care about the distance.
                        Data.requestStory
            getRemoteDataStoreUpdater id = Remote.DataStore.fetch id requestRemoteStory Data.updateStory
            logViewThenReturnUpdater id =
                Data.viewStory id `Task.andThen` (\_ -> getRemoteDataStoreUpdater id)
        in
            Effects.task
                <| Task.map LoadData (logViewThenReturnUpdater storyId)
                --<| Data.viewStory storyId -- log the view
                --`Task.andThen` \_ -> Remote.DataStore.fetch storyId requestRemoteStory Data.updateStory
                -- which is all just to say,
                -- View storyId -> Effects (LoadData (RemoteDataStore id a -> RemoteDataStore id a))
    UpdateLocation loc ->
        if app.discovery == initialDiscovery then
            case loc of
                Just latlng -> Debug.log "UpdateLocation: got LatLng" fetchDiscover <| Data.requestNearbyStories latlng
                Nothing -> Debug.log "UpdateLocation: got Nothing"  fetchDiscover <| Data.requestStories
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
        Viewing _ view _-> case view.photoPosition of
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
    _ -> (Debug.log "updateAction action triggered: " Effects.none)



----------------------------------------------------  helpers


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
animateItem discovery time window =
    { discovery | itemPosition = Swiping.animateStep time window discovery.itemPosition }


{-| Move items that are swiped while being discovered -}
moveItem : Discovery a -> ItemPosition -> Discovery a
moveItem discovery pos = {discovery | itemPosition = pos}


{-| Update the app with new discovery stories -}
updateDiscoverableItems : Discovery id -> RemoteData (List id) -> Discovery id
updateDiscoverableItems discovery items =
    if discovery == initialDiscovery then
        { discovery |
          item = Remote.Data.map List.head items
        , items = Remote.Data.get items |> tailOrEmptyList
        }
    else
        discovery


{-| Get all but the first of the list, or an empty list if list itself was either Nothing or empty.

Basically it's like List.tail but handles Maybes.

```
    tailOrEmptyList (Just [1,2,3]) == [2,3]
    tailOrEmptyList (Just []) = []
    tailOrEmptyList Nothing == []
```
-}
tailOrEmptyList : Maybe (List a) -> List a
tailOrEmptyList list = list `Maybe.andThen` List.tail |> Maybe.withDefault []


{-| Take a HTTP request and create an action to update the app with new discovery stories.

This function dynamically generates a function, unique to any given list of stories,
which, when supplied with a remote data store will update that datastore with those stories.

That generated function is turned into one of the `Action`s defined in Types.elm through
the use of a type constructor like `LoadData`, so you
can expect AppAction to be a type like this:
```
    LoadData (RemoteDataStore id a -> RemoteDataStore id a)
```

You could then use Elm's pattern matching in `updateModel` to catch the update action:

```
    case action of
        LoadData updateItems-> {app | items = updateItems app.items}
```

-}
fetchDiscover : Task Http.Error (List Story) -> Effects.Effects AppAction
fetchDiscover requestStoriesTask =
    let
        update_ story = Remote.DataStore.update (Story.id story) (Data.updateStory <| Loaded story)
        -- update_ : Story -> RemoteDataStore StoryId Story -> RemoteDataStore StoryId Story
        -- update_ story : RemoteDataStore StoryId Story -> RemoteDataStore StoryId Story
    in
        Effects.task
            <| requestStoriesTask
            `Task.andThen`
                (\stories -> -- create a function of type List Story -> Task a (Action StoryId Story)
                    (\dataStore ->
                        List.foldl update_ dataStore stories -- type: RemoteDataStore StoryId Story
                    )
                    |> LoadDiscoveryData (Loaded <| List.map Story.id stories)
                    |> Task.succeed)
            `Task.onError`
                (\error -> LoadDiscoveryData (Failed error) identity |> Task.succeed)


{-| The initial state of a singular item being viewed -}
initialItemView : ItemView
initialItemView = {photoIndex = 0, photoPosition = Static}

