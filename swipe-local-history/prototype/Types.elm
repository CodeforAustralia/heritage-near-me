module Types (App(..), Exploration, Favourites, Story, Action(..)) where

type App a =
      Exploring (Exploration a)
    | Viewing a (Exploration a)
    | ViewingFavourites (Exploration a)

type Action a =
      Explore
    | Favourite
    | Pass
    | View a
    | ViewFavourites
    | NoAction

type alias Exploration a =
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
