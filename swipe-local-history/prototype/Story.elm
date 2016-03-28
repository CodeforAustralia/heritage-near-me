module Story (view, id, title, blurb, photo, photos, distance) where

import Date exposing (Date)
import Date.Format
import Date.Config.Config_en_au as AuDate
import List.Extra as List

import Html exposing (Html, div, h1, h2, h3, h4, blockquote, img, ul, li, br, span, a, i, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)
import Markdown
import Number.Format

import Types exposing (..)
import Remote.Data exposing (RemoteData(..))
import Loading exposing (loading)
import Swiping exposing (onSwipe, swipePhotoAction, itemSwipe, itemPos)

{-| The main HTML view for an individual story.
Displays a simpler view if only part of the story is available.
-} 
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
                    , case story.author of
                        Just authorName -> author authorName
                        Nothing -> author "Heritage Near Me"
                    , links story
                    ]
        Failed _ ->
            [ text "Something went wrong"]
        Loading ->
            [ loading ]

{-| The dots below the photo slide which allow a user to switch the photo being viewed -}
photoIndicators address story index = div
    [class "photo-indicators"]
    <| List.indexedMap (\index' _ ->
        if index' == storyIndex index story then
            i [class "fa fa-circle"] []
        else
            i [class "fa fa-circle-o", onClick address <| JumpPhoto index'] []
    ) <| photos story

{-| The HTML for story authorship
Includes Creative Commons attribution -}
author name = let
        license = a
            [ rel "license"
            , href "http://creativecommons.org/licenses/by/4.0/"
            ]
    in
        div [class "author"]
            [ license
                [ img
                    [ alt "Creative Commons License"
                    , src "https://i.creativecommons.org/l/by/4.0/80x15.png"
                    ] []
                ]
            , br [] []
            , text "This work by "
            , span [] [text name]
            , text " is licensed under a "
            , license [text "Creative Commons Attribution 4.0 International License"]
            ]

{-| The HTML for the links that appear at after the story -}
links story = let
        heritageUrl = "http://www.environment.nsw.gov.au/heritageapp/visit/ViewAttractionDetail.aspx?ID=" 
        sites = List.map (\site -> li [] [link site.name (heritageUrl ++ site.id)]) story.sites 
        links = List.map (\link' -> li [] [link link'.label link'.url]) story.links 
    in
        case sites ++ links of
            [] -> text ""
            links -> div [class "links"]
                [ h4 [] [text "Further Reading"]
                , ul [class "links"] links
                ] 

{-| The HTML for a single story link -}
link : String -> String -> Html
link name url = a [href url]
    [ text name
    , span [class "link-arrow"]
        [ span [class "external-link"] [text "External Link"]
        , i [class "fa fa-angle-right"] []
        ]
    ]

{-| The HTML style for a photo which can be swiped -}
storyImage story pos index = div
    [ class "image"
    , style <|
        [ ("background-image", "url(\"" ++ (Maybe.withDefault (photo story) <| List.getAt (photos story) <| storyIndex index story) ++ "\")")
        , ("background-repeat", "no-repeat")
        , ("background-size", "cover")
        ] ++ photoPosition pos
    ] []

{-| The HTML style just for positioning a photo which can be swiped -}
photoPosition pos =
    [ ("position", "relative")
    , ("left", toString (Maybe.withDefault 0 <| itemPos pos) ++ "px")
    ]

{-| The current index of a photo in the slideshow which can loop around -}
storyIndex : Int -> Story -> Int
storyIndex index story = index % (List.length <| photos story)

{-| The id of a story -}
id : Story -> StoryId
id story = case story of
    DiscoverStory story -> story.id
    FullStory story -> story.id

{-| The title of a story -}
title : Story -> String
title story = case story of
    DiscoverStory story -> story.title
    FullStory story -> story.title

{-| The blurb of a story -}
blurb : Story -> String
blurb story = case story of
    DiscoverStory story -> story.blurb
    FullStory story -> story.blurb

{-| The photo of a story -}
photo : Story -> String
photo story = case story of
    DiscoverStory story -> story.photo
    FullStory story -> Maybe.withDefault "" <| List.head story.photos

{-| A list of a story's photos -}
photos : Story -> List String
photos story = case story of
    DiscoverStory story -> [story.photo]
    FullStory story -> story.photos

{-| The distance to a story -}
distance : Story -> Maybe String
distance story = case story of
    DiscoverStory story -> Maybe.map distanceFormat story.distance
    FullStory story -> Nothing

{-| Format a story's date range -}
formatDate : Dates -> Maybe String
formatDate dates = case (dates.start, dates.end) of
    (Just start, Nothing) -> Just <| dateFormat "%Y" start
    (Nothing, Just end) -> Just <| dateFormat "%Y" end
    (Just start, Just end) -> Just
        <| dateFormat "%Y" start ++ " - " ++ dateFormat "%Y" end
    _ -> Nothing

{-| Function for formatting a generic date -}
dateFormat : String -> Date -> String
dateFormat = Date.Format.format AuDate.config 

{-| Format a distance in meters -}
distanceFormat : Float -> String
distanceFormat dist = if dist < 10 then
        "Here"
    else if dist < 1000 then
        toString (digits 1 dist) ++ "m"
    else if dist < 5000 then
        Number.Format.pretty 1 ',' (dist / 1000) ++ "km"
    else if dist < 10000 then
        toString (digits 1 (dist / 1000)) ++ "km"
    else
        toString (digits 2 (dist / 1000)) ++ "km"

{-| Round to the first n digits of a Float -}
digits : Int -> Float -> Int
digits n f = let
        base = 10
        places = ceiling (logBase base f) - n
    in
        if places < 0 then
            n
        else
            (round (f / toFloat (base^places))) * base^places
