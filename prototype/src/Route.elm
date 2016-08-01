module Route (action, url) where

import Story exposing (storyIdToStr)

import String
import Result
import RouteHash exposing (HashUpdate)

import Types exposing (..)

{-| Turn a browser URL into an action to update the app -}
action : List String -> List AppAction
action url = case url of
    "discover"::_ -> [Discover]
    "favourites"::_ -> [ViewFavourites]
    "story"::storyId::storyScreen::_ ->
        let
            id = parseStoryId storyId
            screen = parseStoryScreen storyScreen
        in
            [View id screen]
    "story"::storyId::_ ->
        let
            id = parseStoryId storyId
            screen = screen1
        in
            [View id screen]
    _ -> Debug.log "converted url into default action: " [Discover]

{-| Turn the difference between two app states into a browser URL -}
url : AppModel -> AppModel -> Maybe HashUpdate
url old new = if old.location /= new.location then
        Just <| case new.location of
            Discovering       -> RouteHash.set ["discover"]
            ViewingFavourites -> RouteHash.set ["favourites"]
            Viewing storyId _ storyScreen -> RouteHash.set ["story", storyIdToStr storyId, urliseStoryScreen storyScreen]
    else
        Nothing


{-| Parse what might be the story ID -}
parseStoryId : String -> StoryId
parseStoryId storyId =
    StoryId <| Maybe.withDefault -1 <| Result.toMaybe <| String.toInt storyId

{-| Parse what might be the story screen -}
parseStoryScreen : String -> StoryScreen
parseStoryScreen storyScreen =
    case storyScreen of
        "body" ->
            Body
        "info" ->
            MoreInfo
        _ -> Intro


{-| Turn a story screen into a string to be used in the URL -}
urliseStoryScreen : StoryScreen -> String
urliseStoryScreen screen =
    case screen of
        Intro ->
            ""
        Body ->
            "body"
        MoreInfo ->
            "info"
