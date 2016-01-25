module Types (App(..), SwipeApp, Story) where

type App a = Exploring (SwipeApp a) | Favourites (SwipeApp a) | Viewing a

type alias SwipeApp a =
    { item : a 
    , items : List a
    , favourites : List a
    }

type alias Story =
    { title : String
    , story : String
    , photo : String
    }
