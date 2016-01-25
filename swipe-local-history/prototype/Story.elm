module Story (view) where

import Html exposing (Html, div, nav, h1, h2, img, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)

import Types exposing (..)

view : Signal.Address (Action Story) -> Story -> Html
view address story = div []
    [ nav [onClick address Explore] [text "< back"]
    , img [src story.photo] []
    , h1 [] [text story.title]
    , div [] [text story.story]
    ]
