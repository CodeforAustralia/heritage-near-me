module Navigation (navigation) where

import Html exposing (Html, div, nav, img, button, a, i, text)
import Html.Attributes exposing (class, src, href)
import Html.Events exposing (onClick)

import Types exposing (..)

{-| The top level navigation view for the app -}
navigation : Signal.Address (Action id a) -> Location id -> Html
navigation address location = nav [class "navigation"]
    [ case location of
        Discovering ->
            button [onClick address ViewFavourites] [i [class "fa fa-heart fa-2x"] []]
        Viewing _ _ ->
            button [onClick address Back] [i [class "fa fa-angle-left fa-3x"] []]
        ViewingFavourites ->
            button [onClick address Discover] [i [class "fa fa-map fa-2x"] []]
    , div [class "logo"] [a [href "/"] [img [src "images/logo.png"] []]]
    ]
