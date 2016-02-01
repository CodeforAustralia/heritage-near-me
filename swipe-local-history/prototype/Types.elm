module Types (App(..), Discovery, Favourites, Story, Action(..)) where

type App a =
      Discovering (Discovery a)
    | Viewing a (Discovery a)
    | ViewingFavourites (Discovery a)

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
