module Discover (view) where

import Html exposing (Html, div, nav, h1, h2, img, button, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)
import Swipe exposing (SwipeState(..))

import Types exposing (..)
import Swiping exposing (onSwipe, swipeAction)
import Data exposing (getItem)
import Story

view : Signal.Address (Action StoryId Story) -> App StoryId Story -> Html
view address app = div [class "discovery"]
    [ case app.discovery.item of
        Loaded (Succeeded item) -> case item of
            Just id -> case getItem app Story.id id of
                Loaded (Succeeded story) -> viewStory address story app.discovery.swipeState
                Loaded (Failed err) -> text "Something went wrong"
                Loading -> text "Loading..."
            Nothing -> noStory
        Loaded (Failed err) -> text "Something went wrong"
        Loading -> text "Loading..."
    , navigation address
    ]

navigation : Signal.Address (Action StoryId Story) -> Html
navigation address = nav [class "discovery-navigation"]
    [ button [onClick address Pass] [text "❌"]
    , button [onClick address Favourite] [text "✅"]
    ]

noStory : Html
noStory = div [class "discovery-empty"] [h2 [] [text "No more stories left!"]]

viewStory : Signal.Address (Action StoryId Story) -> Story -> Maybe SwipeState -> Html
viewStory address story swipe = div
    ([ onClick address <| View <| Story.id story
    , class "discovery-story"
    , style <| styleStory swipe
    ] ++ onSwipe address swipe swipeAction)
    [ storyImage story
    , h2 [] [text <| Story.title story]
    ]

storyImage story = div
    [ class "image"
    , style [ ("background-image", "url(\"" ++ Story.photo story ++ "\")")
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
