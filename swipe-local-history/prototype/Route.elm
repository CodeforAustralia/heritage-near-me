module Route (action, url) where

import String
import RouteHash exposing (HashUpdate)

import Types exposing (..)

action : List String -> List (Action StoryId Story)
action url = case url of
    "discover"::_ -> [Discover]
    "favourites"::_ -> [ViewFavourites]
    _ -> [Discover]

url : App StoryId Story -> App StoryId Story -> Maybe HashUpdate
url old new = if old.location /= new.location then
        Just <| case new.location of
            Discovering       -> RouteHash.set ["discover"]
            ViewingFavourites -> RouteHash.set ["favourites"]
            Viewing storyId   -> RouteHash.set ["story", urliseStory storyId]
    else
        Nothing

urliseStory : StoryId -> String
urliseStory storyId = toString storyId
