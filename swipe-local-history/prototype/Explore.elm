module Explore (view) where

import Html exposing (Html, div, h1, h2, img, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)

import Types exposing (..)

view : Signal.Address (Action Story) -> Exploration Story -> Html
view address app = div []
    <| List.map (viewStory address) app.items

viewStory : Signal.Address (Action Story) -> Story -> Html
viewStory address story = div [onClick address <| View story]
    [ img [src story.photo] []
    , h2 [] [text story.title]
    ]
