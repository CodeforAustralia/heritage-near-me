module Types (App, Location(..), Discovery, Favourites, Story, Action(..)) where

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
    | Favourite
    | Pass
    | View a
    | ViewFavourites
    | NoAction

type alias Discovery a =
    { item : Maybe a
    , items : List a
    , favourites : Favourites a
    , passes : List a
    }

type alias Favourites a = List a

type alias Story =
    { title : String
    , story : String
    , photo : String
    }
