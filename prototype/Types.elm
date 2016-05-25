module Types (App, Location(..), Discovery, ItemView, Favourites, StoryId(..), Story(..), Site, LatLng, Dates, Action(..), ItemPosition(..), Window) where

import Remote.DataStore exposing (RemoteDataStore)
import Remote.Data exposing (RemoteData)
import Date exposing (Date)
import Dict exposing (Dict)
import Swipe exposing (SwipeState)
import Time exposing (Time)

type alias App id a =
    { location : Location id
    , discovery : Discovery id
    , items : RemoteDataStore id a
    }

type Location id =
      Discovering
    | Viewing id ItemView
    | ViewingFavourites

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
    | View id
    | ViewFavourites
    | Back
    | LoadData (RemoteDataStore id a -> RemoteDataStore id a)
    | LoadDiscoveryData (RemoteData (List id)) (RemoteDataStore id a -> RemoteDataStore id a)
    | NoAction

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

type alias Favourites a = List a

type StoryId = StoryId Int

type Story =
      DiscoverStory
        { id : StoryId
        , title : String
        , blurb : String
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
        , sites : List Site
        , locations : List LatLng
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