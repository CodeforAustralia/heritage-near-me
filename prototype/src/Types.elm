module Types (AppModel, AppAction, AppLocation, Location(..), Discovery, ItemView, StoryScreen(..), screen1, Favourites, StoryId(..), Story(..), Site, LatLng, Dates, Action(..), ItemPosition(..), Window) where

import Remote.DataStore exposing (RemoteDataStore)
import Remote.Data exposing (RemoteData)
import Date exposing (Date)
import Swipe exposing (SwipeState)
import Time exposing (Time)

type alias AppModel = App StoryId Story

type alias App id a =
    { location : Location id
    , discovery : Discovery id
    , items : RemoteDataStore id a
    , latLng : Maybe LatLng -- the browser's latitude,longitude coordinates, if we have them.
    }

type alias AppLocation = Location StoryId

{-| Location is the screen / view / page the user is on.

App screens:
    * Discovering: the app home page where you get a summary of a story and the option to like or pass it.
    * Viewing <story id>: You are looking at a particular story.
    * ViewingFavourites: You are looking at your list of favourite stories.
-}
type Location id =
      Discovering
    | Viewing id ItemView StoryScreen
    | ViewingFavourites


{-| AppAction is just a shortcut for the `Action` type.

It allows you to skip using the type parameters; that is, instead of saying
a function takes an `Action id a` (where `id` would be a `StoryId` and
`a` would just be a `Story`), you'll almost always just say the function
takes an `AppAction`.
-}
type alias AppAction = Action StoryId Story

type Action id a =
      Discover
    | UpdateLocation (Maybe LatLng)
    | Animate Time Window
    | MoveItem ItemPosition
    | Favourite
    | Pass
    | MovePhoto ItemPosition
    | PrevPhoto
    | NextPhoto
    | JumpPhoto Int
    | View id StoryScreen
    | ViewFavourites
    | Back
    | LoadData UpdaterFunction
    | LoadDiscoveryData (RemoteData (List id)) UpdaterFunction
    | NoAction

type alias UpdaterFunction = (RemoteDataStore StoryId Story -> RemoteDataStore StoryId Story)


type ItemPosition = Static
    | Swiping SwipeState
    | Return Float
    | Returning Window Float Time Time Time
    | Leave Float
    | Leaving Window Float Time Time Time

type alias Discovery id =
    { item : RemoteData (Maybe id)
    , itemPosition : ItemPosition
    , items : List id
    , favourites : Favourites id
    , passes : List id
    }

type alias ItemView =
    { photoIndex : Int
    , photoPosition : ItemPosition
    }

type StoryScreen = Intro | Body

screen1 : StoryScreen
screen1 = Intro -- default screen


type alias Favourites a = List a

type StoryId = StoryId Int

type Story =
      DiscoverStory
        { id : StoryId
        , title : String
        , blurb : String
        , sites : List Site
        , photo : String
        , distance : Maybe Float
        }
    | FullStory
        { id : StoryId
        , title : String
        , blurb : String
        , suburb : Maybe String
        , dates : Dates
        , photos : List String
        , story : String
        , quote : String
        , sites : List Site
        , locations : List LatLng
        , distance : Maybe Float
        }

type alias LatLng =
    { lat : String
    , lng : String
    }

type alias Site =
    { id : String
    , name : String
    }

type alias Dates =
    { start : Maybe Date
    , end : Maybe Date
    }

type alias Window =
     { width : Float
     , height : Float
     }
