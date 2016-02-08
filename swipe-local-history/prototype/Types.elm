module Types (App, Location(..), Discovery, Favourites, StoryId(..), Story(..), Action(..), RemoteData(..), LoadedData(..)) where

import Http
import Dict exposing (Dict)
import Swipe exposing (SwipeState)

type alias App id a =
    { location : Location id
    , discovery : Discovery id
    , items : Dict String (RemoteData a)
    }

type Location id =
      Discovering
    | Viewing id
    | ViewingFavourites

type Action id a =
      Discover
    | SwipingItem (Maybe SwipeState)
    | Favourite
    | Pass
    | View id
    | ViewFavourites
    | LoadItem (LoadedData a)
    | LoadItems (LoadedData (List a))
    | NoAction

type RemoteData a = Loading | Loaded (LoadedData a)
type LoadedData a = Succeeded a | Failed Http.Error

type alias Discovery id =
    { item : RemoteData (Maybe id)
    , swipeState : Maybe SwipeState
    , items : List id
    , favourites : Favourites id
    , passes : List id
    }

type alias Favourites a = List a

type StoryId = StoryId Int

type Story =
      DiscoverStory
        { id : StoryId
        , title : String
        , photo : String
        }
    | FullStory
        { id : StoryId
        , title : String
        , photos : List String
        , story : String
        }
