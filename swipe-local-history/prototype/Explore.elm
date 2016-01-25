module Explore (view) where

import Html exposing (Html, div, nav, h1, h2, img, button, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)

import Types exposing (..)

view : Signal.Address (Action Story) -> Exploration Story -> Html
view address app = div []
    [ case app.item of
        Just item -> viewStory address item
        Nothing   -> text "No more stories left!"
    , navigation address app
    ]

navigation : Signal.Address (Action Story) -> (Exploration Story) -> Html
navigation address app = nav []
    [ button [onClick address Pass] [text "❌"]
    , button [onClick address Favourite] [text "✅"]
    ]

viewStory : Signal.Address (Action Story) -> Story -> Html
viewStory address story = div [onClick address <| View story]
    [ img [src story.photo] []
    , h2 [] [text story.title]
    ]
