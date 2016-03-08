module Story (view, id, title, blurb, photo, photos) where

import Date exposing (Date)
import Date.Format as Date
import List.Extra as List

import Html exposing (Html, div, h1, h2, h3, h4, blockquote, img, ul, li, span, a, i, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)
import Markdown

import Types exposing (..)
import Remote.Data exposing (RemoteData(..))
import Loading exposing (loading)
import Swiping exposing (onSwipe, swipePhotoAction, itemSwipe, itemPos)

view : Signal.Address (Action StoryId Story) -> RemoteData Story -> ItemView -> Html
view address story item = div [class "story"]
    <| case story of
        Loaded story ->
            [ if (List.length <| photos story) > 1 then
                    div
                        ([class "photo-slide"] ++ onSwipe address (itemSwipe item.photoPosition) swipePhotoAction)
                        [ div [class "photos"]
                            <| List.map (storyImage story item.photoPosition) [item.photoIndex-1, item.photoIndex, item.photoIndex+1]
                        , photoIndicators address story item.photoIndex
                        ]
                else
                    div
                        [class "photos"]
                        [storyImage story item.photoPosition item.photoIndex] 
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
        Failed _ ->
            [ text "Something went wrong"]
        Loading ->
            [ loading ]

photoIndicators address story index = div
    [class "photo-indicators"]
    <| List.indexedMap (\index' _ ->
        if index' == storyIndex index story then
            i [class "fa fa-circle"] []
        else
            i [class "fa fa-circle-o", onClick address <| JumpPhoto index'] []
    ) <| photos story

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
        [ ("background-image", "url(\"" ++ (Maybe.withDefault (photo story) <| List.getAt (photos story) <| storyIndex index story) ++ "\")")
        , ("background-repeat", "no-repeat")
        , ("background-size", "cover")
        ] ++ photoPosition pos
    ] []

storyIndex : Int -> Story -> Int
storyIndex index story = index % (List.length <| photos story)

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
