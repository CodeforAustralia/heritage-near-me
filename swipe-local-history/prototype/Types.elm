module Types (App, Location(..), Discovery, Favourites, Story, Action(..), RemoteData(..), LoadedData(..)) where

import Http
import Swipe exposing (SwipeState)

type alias App a =
    { location : Location a
    , discovery : Discovery a
    }

type Location a =
      Discovering
    | Viewing a
    | ViewingFavourites

type Action a =
      Discover
    | SwipingItem (Maybe SwipeState)
    | Favourite
    | Pass
    | View a
    | ViewFavourites
    | LoadItems (LoadedData (List a))
    | NoAction

type RemoteData a = Loading | Loaded (LoadedData a)
type LoadedData a = Succeeded a | Failed Http.Error

type alias Discovery a =
    { item : RemoteData (Maybe a)
    , swipeState : Maybe SwipeState
    , items : RemoteData (List a)
    , favourites : Favourites a
    , passes : List a
    }

type alias Favourites a = List a

type alias Story =
    { title : String
    , story : String
    , photo : String
    }
