module Story (view, id, title, photo) where

import Html exposing (Html, div, h1, h2, img, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)
import Markdown

import Types exposing (..)
import Loading exposing (loading)

view : Signal.Address (Action StoryId Story) -> RemoteData Story -> Html
view address story = div [class "story"]
    <| case story of
        Loaded (Succeeded story) ->
            [ storyImage story
            , h1 [class "title"] [text <| title story]
            , case story of
                DiscoverStory story -> loading
                FullStory story -> Markdown.toHtml story.story
            ]
        Loaded (Failed _) ->
            [ text "Something went wrong"]
        Loading ->
            [ loading ]

storyImage story = div
    [ class "image"
    , style [ ("background-image", "url(\"" ++ photo story ++ "\")")
            , ("background-repeat", "no-repeat")
            , ("background-size", "cover")]
    ] []

id : Story -> StoryId
id story = case story of
    DiscoverStory story -> story.id
    FullStory story -> story.id

title : Story -> String
title story = case story of
    DiscoverStory story -> story.title
    FullStory story -> story.title

photo : Story -> String
photo story = case story of
    DiscoverStory story -> story.photo
    FullStory story -> Maybe.withDefault "" <| List.head story.photos
