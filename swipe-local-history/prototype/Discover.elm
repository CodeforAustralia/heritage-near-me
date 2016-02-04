module Discover (view) where

import Html exposing (Html, div, nav, h1, h2, img, button, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)
import Swipe exposing (SwipeState(..))

import Types exposing (..)
import Swiping exposing (onSwipe, swipeAction)

view : Signal.Address (Action Story) -> Discovery Story -> Html
view address app = div [class "discovery"
    ]
    [ case app.item of
        Just item -> viewStory address item app.swipeState
        Nothing   -> noStory
    , navigation address app
    ]

navigation : Signal.Address (Action Story) -> (Discovery Story) -> Html
navigation address app = nav [class "discovery-navigation"]
    [ button [onClick address Pass] [text "❌"]
    , button [onClick address Favourite] [text "✅"]
    ]

noStory : Html
noStory = div [class "discovery-empty"] [h2 [] [text "No more stories left!"]]

viewStory : Signal.Address (Action Story) -> Story -> Maybe SwipeState -> Html
viewStory address story swipe = div
    ([ onClick address <| View story
    , class "discovery-story"
    , style <| styleStory swipe
    ] ++ onSwipe address swipe swipeAction)
    [ storyImage story
    , h2 [] [text story.title]
    ]

storyImage story = div
    [ class "image"
    , style [ ("background-image", "url(\"" ++ story.photo ++ "\")")
            , ("background-repeat", "no-repeat")
            , ("background-size", "cover")]
    ] []

styleStory : Maybe SwipeState -> List (String, String)
styleStory swipe = case swipe of
    Just (Swiping state) ->
        [ ("position", "relative")
        , ("left", toString (state.x1 - state.x0) ++ "px")
        ]
    _ ->
        []
