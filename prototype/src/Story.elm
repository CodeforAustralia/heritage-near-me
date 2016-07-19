module Story (view, id, storyIdToStr, title, storySiteName, photo, photos, distance) where

import Date exposing (Date)
import Date.Format
import Date.Config.Config_en_au as AuDate
import List.Extra as List

import Html exposing (Html, div, h1, h2, h3, h4, p, blockquote, img, ul, li, span, a, i, text)
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
view : Signal.Address AppAction -> RemoteData Story -> ItemView -> Html
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
                DiscoverStory discoverStory -> [loading]
                FullStory fullStory -> [
                    div [class "fullStory-meta"] [
                        div [class "fullStory-site"] [text (sitesName fullStory.sites)]
                        , case fullStory.suburb of
                            Just suburb -> div [class "fullStory-suburb"] [text suburb]
                            Nothing -> text ""
                        , case formatDate fullStory.dates of
                            Just date -> div [class "fullStory-date"] [text date]
                            Nothing -> text ""
                        ,  case distance story of
                            Just distance -> p [class "fullStory-distance"] [i [class "fa fa-map-marker"] [], text " ", text distance]
                            Nothing -> text "got-no-distance"
                    ]
                    , blockquote [] [text fullStory.blurb]
                    , case (List.head fullStory.locations) of
                        Just latlng -> div [class "directions"] [a [href ("https://www.google.com/maps/dir/Current+Location/" ++ latlng.lat ++ "," ++ latlng.lng), target "_blank"] [text "Directions"]]
                        Nothing -> text ""
                    , div [class "passage"] [Markdown.toHtml fullStory.story]
                    , case fullStory.sites of
                        [] -> text ""
                        _ -> links fullStory
                    ]
        Failed error ->
            [ text "Something went wrong: ", text <| toString <| log error]
        Loading ->
            [ loading ]

log : a -> a
log anything =
    Debug.log "" anything

{-| The dots below the photo slide which allow a user to switch the photo being viewed -}
photoIndicators address story index = div
    [class "photo-indicators"]
    <| List.indexedMap (\index' _ ->
        if index' == storyIndex index story then
            i [class "fa fa-circle"] []
        else
            i [class "fa fa-circle-o", onClick address <| JumpPhoto index'] []
    ) <| photos story

{-| The HTML for the links that appear at after the story -}
links story = let
        heritageUrl = "http://www.environment.nsw.gov.au/heritageapp/visit/ViewAttractionDetail.aspx?ID=" 
    in
        div [class "links"]
            [ h4 [] [text "Further Reading"]
            , ul [class "links"]
                <| List.map (\site -> li [] [link site.name (heritageUrl ++ site.id)]) story.sites 
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

{-| Returns the StoryId as a string.
```
    id = StoryId 5
    storyIdToStr id == "5"
```
-}
storyIdToStr : StoryId -> String
storyIdToStr (StoryId id) = toString id

--id : { story | id : String } -> String
--id story = story.id

{-| The title of a story -}
title : Story -> String
title story = case story of
    DiscoverStory story -> story.title
    FullStory story -> story.title

--title : {title: String} -> String
--title s = s.title

{-| The blurb of a story -}
--blurb : Story -> String
--blurb story = case story of
--    DiscoverStory story -> story.blurb
--    FullStory story -> story.blurb

{-| The blurb of a story -}
--blurb : { x | blurb:String } -> String
--blurb story =
--    story.blurb


{-| The associated site name of a story -}
storySiteName : Story -> String
storySiteName story =
    case story of
        DiscoverStory story ->
            sitesName story.sites

        FullStory story ->
            sitesName story.sites


{-| Provides site name (summary) for stories with one or more sites -}
sitesName : List Site -> String
sitesName sites =
    case sites of
        [] -> ""
        [a] -> a.name
        a :: _ -> "Multiple Sites"


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
    FullStory story -> Maybe.map distanceFormat story.distance

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
