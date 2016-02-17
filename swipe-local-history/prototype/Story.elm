module Story (view, id, title, blurb, photo, photos) where

import Date exposing (Date)
import Date.Format as Date
import List.Extra as List

import Html exposing (Html, div, h1, h2, h3, h4, blockquote, img, ul, li, span, a, i, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)
import Markdown

import Types exposing (..)
import Loading exposing (loading)
import Swiping exposing (onSwipe, swipePhotoAction, itemSwipe, itemPos)

view : Signal.Address (Action StoryId Story) -> RemoteData Story -> ItemView -> Html
view address story item = div [class "story"]
    <| case story of
        Loaded (Succeeded story) ->
            [ div
                ([class "photos"] ++ onSwipe address (itemSwipe item.photoPosition) swipePhotoAction)
                <| List.map (storyImage story item.photoPosition) [item.photoIndex-1, item.photoIndex, item.photoIndex+1]
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
                    , case story.sites of
                        [] -> text ""
                        _ -> links story
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
link name url = a [href url]
    [ text name
    , span [class "link-arrow"]
        [ span [class "external-link"] [text "External Link"]
        , i [class "fa fa-angle-right"] []
        ]
    ]

photoPosition pos =
    [ ("position", "relative")
    , ("left", toString (Maybe.withDefault 0 <| itemPos pos) ++ "px")
    ]

storyImage story pos index = div
    [ class "image"
    , style <|
        [ ("background-image", "url(\"" ++ (Maybe.withDefault (photo story) <| List.getAt (photos story) index) ++ "\")")
        , ("background-repeat", "no-repeat")
        , ("background-size", "cover")
        ] ++ photoPosition pos
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

photos : Story -> List String
photos story = case story of
    DiscoverStory story -> [story.photo]
    FullStory story -> story.photos
