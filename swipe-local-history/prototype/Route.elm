module Route (action, url) where

import String
import Result
import RouteHash exposing (HashUpdate)

import Types exposing (..)

action : List String -> List (Action StoryId Story)
action url = case url of
    "discover"::_ -> [Discover]
    "favourites"::_ -> [ViewFavourites]
    "story"::storyId::_ -> [View <| StoryId <| Maybe.withDefault -1 <| Result.toMaybe <| String.toInt storyId]
    _ -> [Discover]

url : App StoryId Story -> App StoryId Story -> Maybe HashUpdate
url old new = if old.location /= new.location then
        Just <| case new.location of
            Discovering       -> RouteHash.set ["discover"]
            ViewingFavourites -> RouteHash.set ["favourites"]
            Viewing storyId _ -> RouteHash.set ["story", urliseStory storyId]
    else
        Nothing

urliseStory : StoryId -> String
urliseStory (StoryId id) = toString id
