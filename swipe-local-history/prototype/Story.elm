module Story (view, id, title, blurb, photo) where

import Date exposing (Date)
import Date.Format as Date

import Html exposing (Html, div, h1, h2, h3, h4, blockquote, img, ul, li, a, text)
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
            ] ++ case story of
                DiscoverStory story -> [loading]
                FullStory story ->
                    [ case story.suburb of
                        Just suburb -> h3 [class "suburb"] [text suburb]
                        Nothing -> text ""
                    , case formatDate story.dates of
                        Just date -> h3 [class "date"] [text date]
                        Nothing -> text ""
                    , blockquote [] [text story.blurb]
                    , Markdown.toHtml story.story
                    , links story
                    ]
        Loaded (Failed _) ->
            [ text "Something went wrong"]
        Loading ->
            [ loading ]

links story = let
        heritageUrl = "http://www.environment.nsw.gov.au/heritageapp/visit/ViewAttractionDetail.aspx?ID=" 
    in
        div [class "links"]
            [ h4 [] [text "Further Reading"]
            , ul [class "links"]
                <| List.map (\site -> li [] [link site.name (heritageUrl ++ site.id)]) story.sites 
            ] 

link : String -> String -> Html
link name url = a [href url] [text name]

storyImage story = div
    [ class "image"
    , style [ ("background-image", "url(\"" ++ photo story ++ "\")")
            , ("background-repeat", "no-repeat")
            , ("background-size", "cover")]
    ] []

formatDate : Dates -> Maybe String
formatDate dates = case (dates.start, dates.end) of
    (Just start, Nothing) -> Just <| Date.format "%Y" start
    (Nothing, Just end) -> Just <| Date.format "%Y" end
    (Just start, Just end) -> Just
        <| Date.format "%Y" start ++ " - " ++ Date.format "%Y" end
    _ -> Nothing

id : Story -> StoryId
id story = case story of
    DiscoverStory story -> story.id
    FullStory story -> story.id

title : Story -> String
title story = case story of
    DiscoverStory story -> story.title
    FullStory story -> story.title

blurb : Story -> String
blurb story = case story of
    DiscoverStory story -> story.blurb
    FullStory story -> story.blurb

photo : Story -> String
photo story = case story of
    DiscoverStory story -> story.photo
    FullStory story -> Maybe.withDefault "" <| List.head story.photos
