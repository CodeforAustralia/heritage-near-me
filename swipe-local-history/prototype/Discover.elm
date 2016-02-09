module Discover (view) where

import Html exposing (Html, div, nav, h1, h2, img, button, span, i, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)
import Swipe exposing (SwipeState(..))

import Types exposing (..)
import Swiping exposing (onSwipe, swipeAction)
import Data exposing (getItem)
import Story

view : Signal.Address (Action StoryId Story) -> App StoryId Story -> Html -> Html
view address app topNav = div [class "app screen-size discovery"]
    [ topNav
    , case app.discovery.item of
        Loaded (Succeeded item) -> case item of
            Just id -> case getItem app id of
                Loaded (Succeeded story) -> viewStory address story app.discovery.swipeState
                Loaded (Failed err) -> text "Something went wrong"
                Loading -> noStory "Loading..."
            Nothing -> noStory "No more stories left!"
        Loaded (Failed err) -> noStory "Something went wrong"
        Loading -> noStory "Loading..."
    , navigation address
    ]

navigation : Signal.Address (Action StoryId Story) -> Html
navigation address = nav [class "discovery-navigation"]
    [ button [onClick address Pass]
        [span [class "fa-stack fa-3x"]
            [ i [class "fa fa-circle fa-stack-2x"] []
            , i [class "fa fa-times fa-stack-1x fa-inverse"] []
            ]]
    , i [class "fa fa-fw fa-share fa-flip-horizontal fa-3x"] []
    , i [class "fa fa-fw fa-share fa-3x"] []
    , button [onClick address Favourite]
        [span [class "fa-stack fa-3x"]
            [ i [class "fa fa-circle fa-stack-2x"] []
            , i [class "fa fa-heart fa-stack-1x fa-inverse"] []
            ]]
    ]

noStory : String -> Html
noStory message = div [class "discovery-empty"] [h2 [] [text message]]

viewStory : Signal.Address (Action StoryId Story) -> Story -> Maybe SwipeState -> Html
viewStory address story swipe = div
    ([ onClick address <| View <| Story.id story
    , class "discovery-story"
    , style <| styleStory swipe
    ] ++ onSwipe address swipe swipeAction)
    [storyImage story
        [ div [class "discovery-story-image"] []
        , div [class "discovery-story-details"]
            [h2 [class "title"] [text <| Story.title story]]]
    ]

storyImage story content = div
    [ class "image"
    , style [ ("background-image", "url(\"" ++ Story.photo story ++ "\")")
            , ("background-repeat", "no-repeat")
            , ("background-size", "cover")]
    ] content

styleStory : Maybe SwipeState -> List (String, String)
styleStory swipe = case swipe of
    Just (Swiping state) ->
        [ ("position", "relative")
        , ("left", toString (state.x1 - state.x0) ++ "px")
        ]
    _ ->
        []
