module Favourites (view) where

import Html exposing (Html, div, h1, h2, img, ul, li, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)

import Types exposing (..)
import Story

view : Signal.Address (Action StoryId Story) -> Favourites Story -> Html
view address favourites = div [class "favourites"]
    [ h1 [] [text "Favourites"]
    , case favourites of
        [] -> text "You have no favourites yet"
        _  -> viewFavourites address favourites
    ]

viewFavourites : Signal.Address (Action StoryId Story) -> Favourites Story -> Html
viewFavourites address favourites = ul []
    <| List.map (viewFavourite address) favourites

viewFavourite : Signal.Address (Action StoryId Story) -> Story -> Html
viewFavourite address favourite = li [onClick address <| View <| Story.id favourite]
    [ favouriteImage favourite
    , h2 [] [text <| Story.title favourite]
    ]

favouriteImage favourite = div
    [ class "image"
    , style [ ("background-image", "url(\"" ++ Story.photo favourite ++ "\")")
            , ("background-repeat", "no-repeat")
            , ("background-size", "cover")]
    ] []

