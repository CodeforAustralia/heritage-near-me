module Discover (view) where

import Html exposing (Html, div, nav, h1, h2, img, button, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)

import Types exposing (..)

view : Signal.Address (Action Story) -> Discovery Story -> Html
view address app = div [class "discovery"]
    [ case app.item of
        Just item -> viewStory address item app.swipePos
        Nothing   -> text "No more stories left!"
    , navigation address app
    ]

navigation : Signal.Address (Action Story) -> (Discovery Story) -> Html
navigation address app = nav [class "discovery-navigation"]
    [ button [onClick address Pass] [text "❌"]
    , button [onClick address Favourite] [text "✅"]
    ]

viewStory : Signal.Address (Action Story) -> Story -> Maybe Int -> Html
viewStory address story pos = div
    [ onClick address <| View story
    , class "discovery-story"
    , style <| styleStory pos
    ]
    [ storyImage story
    , h2 [] [text story.title]
    ]

storyImage story = div
    [ class "image"
    , style [ ("background-image", "url(\"" ++ story.photo ++ "\")")
            , ("background-repeat", "no-repeat")
            , ("background-size", "cover")]
    ] []

styleStory : Maybe Int -> List (String, String)
styleStory pos = case pos of
    Just pos ->
        [ ("position", "relative")
        , ("left", toString pos ++ "px")
        ]
    Nothing ->
        []
