module Discover (view) where

import Html exposing (Html, div, nav, h1, h2, img, button, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)

import Types exposing (..)

view : Signal.Address (Action Story) -> Discovery Story -> Html
view address app = div []
    [ case app.item of
        Just item -> viewStory address item app.swipePos
        Nothing   -> text "No more stories left!"
    , navigation address app
    ]

navigation : Signal.Address (Action Story) -> (Discovery Story) -> Html
navigation address app = nav []
    [ button [onClick address Pass] [text "❌"]
    , button [onClick address Favourite] [text "✅"]
    ]

viewStory : Signal.Address (Action Story) -> Story -> Maybe Int -> Html
viewStory address story pos = div
    [ onClick address <| View story
    , style <| styleStory pos
    ]
    [ img [src story.photo] []
    , h2 [] [text story.title]
    ]

styleStory : Maybe Int -> List (String, String)
styleStory pos = case pos of
    Just pos ->
        [ ("position", "relative")
        , ("left", toString pos ++ "px")
        ]
    Nothing ->
        []
