module Story (view, update) where

import Html exposing (Html, div, h1, h2, img, text)
import Html.Attributes as Attr exposing (..)

import Types exposing (..)

view : Signal.Address Story -> Story -> Html
view address story = div []
    [ img [src story.photo] []
    , h1 [] [text story.title]
    , div [] [text story.story]
    ]

update : Story -> Story -> Story
update newStory oldStory = newStory
