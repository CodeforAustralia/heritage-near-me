module Story (view, id, storyIdToStr, title, storySiteName, photo, photos, distance, viewStoryAction) where

import Date exposing (Date)
import Date.Format
import Date.Config.Config_en_au as AuDate
import List.Extra as List

import Html exposing (Html, div, h1, h2, h3, h4, p, blockquote, img, ul, li, span, a, button, i, text)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (..)
import Markdown
import Number.Format
import String

import Types exposing (..)
import Remote.Data exposing (RemoteData(..))
import Loading exposing (loading)
import Swiping exposing (onSwipe, swipePhotoAction, itemSwipe, itemPos)

{-| The main HTML view for an individual story.
Displays a simpler view if only part of the story is available.
-} 
view : Signal.Address AppAction -> RemoteData Story -> ItemView -> StoryScreen -> Html
view address story item storyScreen = div [class "story"]
    <| case story of
        Loaded story ->
            [ photoSlider address story item storyScreen
            , metaHtml story storyScreen
            ] ++ case story of
                DiscoverStory discoverStory -> [loading]
                FullStory fullStory -> [
                    buttons address story storyScreen
                    , introOrBody story storyScreen
                    , moreInfo address story storyScreen
                    ]
        Failed error ->
            [ div [class "error"] [text "Something went wrong: ", text <| toString <| log error]]
        Loading ->
            [ loading ]


metaHtml : Story -> StoryScreen -> Html
metaHtml story screen =
    case (story, screen) of

        (DiscoverStory _, _) ->
            titleHtml story

        (FullStory _, MoreInfo) ->
            text ""

        (FullStory fullStory, _) ->

             div [class "fullStory-meta"] [
                titleHtml story
                , div [class "fullStory-site"] [text (sitesName fullStory.sites)]
                , case fullStory.suburb of
                    Just suburb -> div [class "fullStory-suburb"] [text suburb]
                    Nothing -> text ""
                , case formatDate fullStory.dates of
                    Just date -> div [class "fullStory-date"] [text date]
                    Nothing -> text ""
                ,  case distance story of
                    Just distance -> p [class "fullStory-distance"] [i [class "fa fa-map-marker"] [], text " ", text distance]
                    Nothing -> p [class "fullStory-distance got-no-distance"] [text "got-no-distance"]
            ]

titleHtml : Story -> Html
titleHtml story = h1 [class "title"] [text <| title story]


{-| Produce buttons for the story intro page, or nothing if we're not on that page.
-}
buttons : Signal.Address AppAction -> Story -> StoryScreen -> Html
buttons address story storyScreen =
    case (story, storyScreen) of
        (FullStory s, Intro) ->
            div [class "buttons"]
                [ button [class "btn btn-story", onClick address (View s.id Body)] [text "Story"]
                , button [class "btn btn-more-info",  onClick address (View s.id MoreInfo)] [text "Info"]
                , locationsToDirections s.locations
                ]
        (_,_) -> text ""


{-| Produce the content for the Story Info page, or nothing if we're not there.
-}
moreInfo : Signal.Address AppAction -> Story -> StoryScreen -> Html
moreInfo address story storyScreen =
    let
        header = div [class "screen-header screen-more-info"]
                    [ h1 [] [text "More Information"]
                    ]
        screen body = div [] [header, body]
    in
        case (story, storyScreen) of
            (FullStory s, MoreInfo) ->
                case s.links of
                    [] -> screen <| text ""
                    _ -> screen <| links s
            _ -> text ""


{-| Get the link to Google directions map for the first location, or nothing if no locations.
-}
locationsToDirections : List LatLng -> Html
locationsToDirections locations =
    case (List.head locations) of
        Just latlng -> a [href ("https://www.google.com/maps/dir/Current+Location/" ++ latlng.lat ++ "," ++ latlng.lng), target "_blank"] [button [class "btn btn-directions directions"] [text "Directions"]]
        Nothing -> text ""


{-| Depending on if we need to show intro or body sub-screen, produce different html -}
introOrBody : Story -> StoryScreen -> Html
introOrBody story storyScreen =
    case (story, storyScreen) of
        (FullStory s, Intro) ->
            p [] [text s.blurb]
        (FullStory s, Body) ->
            div [class "passage"] [Markdown.toHtml (addQuote s.quote s.story)]
        (_, _) -> text ""

photoSlider : Signal.Address AppAction -> Story -> ItemView -> StoryScreen -> Html
photoSlider address story item screen =
    if screen == Intro && (List.length <| photos story) > 1 then
        div
            ([class "photo-slide"] ++ onSwipe address (itemSwipe item.photoPosition) swipePhotoAction)
            [ div [class "photos"]
                <| List.map (storyImage story item.photoPosition) [item.photoIndex-1, item.photoIndex, item.photoIndex+1]
            , photoIndicators address story item.photoIndex
            ]
    else if screen == Body then
        div
            [class "photos"]
            [storyImage story item.photoPosition item.photoIndex]
    else
        text ""

log : a -> a
log anything =
    Debug.log "" anything

{-| The dots below the photo slide which allow a user to switch the photo being viewed -}
photoIndicators : Signal.Address AppAction -> Story -> Int -> Html
photoIndicators address story index = div
    [class "photo-indicators"]
    <| List.indexedMap (\index' _ ->
        if index' == storyIndex index story then
            i [class "fa fa-circle"] []
        else
            i [class "fa fa-circle-o", onClick address <| JumpPhoto index'] []
    ) <| photos story

{-| The HTML for the links that appear at after the story -}
links story =
    div [class "links"]
        [ h4 [] [text "Further Reading"]
        , ul [class "links"]
            <| List.map (\link -> li [] [linkHtml link.title link.url]) story.links
        ]


{-| The HTML for a single story link -}
linkHtml : String -> String -> Html
linkHtml name url = a [href url]
    [ text name
    , span [class "link-arrow"]
        [ span [class "external-link"] [text "External Link"]
        , i [class "fa fa-angle-right"] []
        ]
    ]

{-| The HTML style for a photo which can be swiped -}
storyImage : Story -> ItemPosition -> Int -> Html
storyImage story pos index = div
    [ class "image"
    , style <|
        [ ("background-image", "url(\"" ++ (Maybe.withDefault (photo story) <| List.getAt (photos story) <| storyIndex index story) ++ "\")")
        , ("background-repeat", "no-repeat")
        , ("background-size", "cover")
        ] ++ photoPosition pos
    ] []

{-| The HTML style just for positioning a photo which can be swiped -}
photoPosition : ItemPosition -> List ( String, String )
photoPosition pos =
    [ ("position", "relative")
    , ("left", toString (Maybe.withDefault 0 <| itemPos pos) ++ "px")
    ]


{-| Add a quote to a markdown story.
Inserts the quote first for very short stories (< 3 lines),
or after the second line for longer stories.

```
    addQuote "hi jesse" "" =
    "> hi jesse"

    addQuote "quote" "one line story" = """
    > quote

    one line story
    """

    addQuote "another quote" """
    some

    multi-line story
    """ = """
    > another quote

    some

    multi-line story
    """

    addQuote "quote3" """
    just a

    3 line

    story
    """ = """
    just a

    3 line

    > quote 3

    story
    """
```
-}
addQuote : String -> String -> String
addQuote quote story =
    case (quote, story) of
        ("", "") -> ""
        ("", story) -> story
        (_, "") -> toMdQuote quote
        (_, _) ->
            let
                lines = String.split "\n\n" story
                shortStory = toMdQuote quote ++ "\n\n" ++ story
                join lines = String.join "\n\n" lines
            in
                case lines of
                    [] ->
                        shortStory
                    line :: [] ->
                        shortStory
                    line :: line2 :: [] ->
                        shortStory
                    line :: line2 :: remainder -> -- longer stories
                        line ++ "\n\n" ++ line2 ++ "\n\n" ++ toMdQuote quote ++ "\n\n" ++ (join remainder)



{-| Turn a string into a markdown quote.
```
    toMdQuote "some quote" = "> some foo"

    toMdQuote """
    some
    multi-line
    quote
    """ = """
    > some
    multi-line
    quote
    """
```
-}
toMdQuote : String -> String
toMdQuote quote = "<blockquote class='featured-quote'>" ++ quote ++ "</blockquote>"



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


{-| Gives the action to jump to a story with default story screen -}
viewStoryAction : Story -> AppAction
viewStoryAction story =
    View (id story) screen1
