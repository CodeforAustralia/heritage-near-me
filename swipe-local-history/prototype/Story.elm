module Story (view) where

import Html exposing (Html, div, h1, h2, img, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)

import Types exposing (..)

view : Signal.Address (Action Story) -> Story -> Html
view address story = div [class "story"]
    [ storyImage story
    , h1 [] [text story.title]
    , div [] [text story.story]
    ]

storyImage story = div
    [ class "image"
    , style [ ("background-image", "url(\"" ++ story.photo ++ "\")")
            , ("background-repeat", "no-repeat")
            , ("background-size", "cover")]
    ] []
