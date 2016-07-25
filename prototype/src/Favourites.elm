module Favourites (view) where

import Html exposing (Html, div, h1, h2, img, ul, li, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)

import Types exposing (..)
import Story

{-| The main HTML view for looking at a user's favourite stories -}
view : Signal.Address AppAction -> Favourites Story -> Html
view address favourites = div [class "favourites"]
    [ case favourites of
        [] -> noStories "You have no favourites yet"
        _  -> viewFavourites address favourites
    ]

{-| The HTML to display when no stories are available for some reason -}
noStories : String -> Html
noStories message = div [class "favourites-empty"] [h2 [] [text message]]

{- The view for a list of favourites -}
viewFavourites : Signal.Address AppAction -> Favourites Story -> Html
viewFavourites address favourites = ul []
    <| List.map (viewFavourite address) favourites

{- The view for a single favourite story in a list of stories -}
viewFavourite : Signal.Address AppAction -> Story -> Html
viewFavourite address favourite = li [onClick address <| View <| Story.id favourite]
    [ favouriteImage favourite
    , h2 [class "title"] [text <| Story.title favourite]
    ]

{- The image for a favourite story -}
favouriteImage favourite = div
    [ class "image"
    , style [ ("background-image", "url(\"" ++ Story.photo favourite ++ "\")")
            , ("background-repeat", "no-repeat")
            , ("background-size", "cover")]
    ] []
