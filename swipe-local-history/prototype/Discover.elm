module Discover (view) where

import Html exposing (Html, div, nav, h1, h2, p, img, button, span, i, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)
import Swipe exposing (SwipeState(..))

import Types exposing (..)
import Loading exposing (loading)
import Swiping exposing (itemSwipe, itemPos, onSwipe, swipeAction)
import Data exposing (getItem)
import Story

view : Signal.Address (Action StoryId Story) -> App StoryId Story -> Html -> Html
view address app topNav = div [class "app screen-size discovery"]
    [ topNav
    , case app.discovery.item of
        Loaded (Succeeded item) -> case item of
            Just id -> case getItem app id of
                Loaded (Succeeded story) -> viewStory address story app.discovery.itemPosition
                Loaded (Failed err) -> noStory "Something went wrong"
                Loading -> div [class "discovery-empty"] [loading]
            Nothing -> noStory "No more stories left!"
        Loaded (Failed err) -> noStory "Something went wrong"
        Loading -> div [class "discovery-empty"] [loading]
    , navigation address
    ]

navigation : Signal.Address (Action StoryId Story) -> Html
navigation address = nav [class "discovery-navigation"]
    [ button [onClick address Pass]
        [span [class "fa-stack fa-3x"]
            [ i [class "fa fa-circle fa-stack-2x"] []
            , i [class "fa fa-times fa-stack-1x fa-inverse"] []
            ]]
    , button [onClick address Pass]
        [i [class "fa fa-fw fa-share fa-flip-horizontal fa-3x"] [] ]
    , button [onClick address Favourite]
        [ i [class "fa fa-fw fa-share fa-3x"] [] ]
    , button [onClick address Favourite]
        [span [class "fa-stack fa-3x"]
            [ i [class "fa fa-circle fa-stack-2x"] []
            , i [class "fa fa-heart fa-stack-1x fa-inverse"] []
            ]]
    ]

noStory : String -> Html
noStory message = div [class "discovery-empty"] [h2 [] [text message]]

viewStory : Signal.Address (Action StoryId Story) -> Story -> ItemPosition -> Html
viewStory address story pos = div
    ([ onClick address <| View <| Story.id story
    , class "discovery-story"
    , style <| styleStory pos
    ] ++ onSwipe address (itemSwipe pos) swipeAction)
    [storyImage story
        [ div [class "discovery-story-image"]
            [ if (Maybe.withDefault 0 <| itemPos pos) > 100 then
                i [class "fa fa-heart favourite"] []
              else if (Maybe.withDefault 0 <| itemPos pos) < -100 then
                i [class "fa fa-times pass"] []
              else
                text ""
            ]
        , div [class "discovery-story-details"]
            [ h2 [class "title"] [text <| Story.title story]
            , p [] [text <| Story.blurb story]
            , case Story.distance story of
                Just distance -> p [class "distance"] [i [class "fa fa-map-marker"] [], text " ", text distance]
                Nothing -> text ""
            ]
        ]
    ]

storyImage story content = div
    [ class "image"
    , style [ ("background-image", "url(\"" ++ Story.photo story ++ "\")")
            , ("background-repeat", "no-repeat")
            , ("background-size", "cover")]
    ] content

styleStory : ItemPosition -> List (String, String)
styleStory pos = case itemPos pos of
    Just p ->
        [ ("position", "relative")
        , ("left", toString p ++ "px")
        ]
    Nothing ->
        []
