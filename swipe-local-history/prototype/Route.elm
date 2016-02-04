module Route (action, url) where

import String
import RouteHash exposing (HashUpdate)

import Types exposing (..)

action : List String -> List (Action Story)
action url = case url of
    "discover"::_ -> [Discover]
    "favourites"::_ -> [ViewFavourites]
    _ -> [Discover]

url : App Story -> App Story -> Maybe HashUpdate
url old new = if old.location /= new.location then
        Just <| case new.location of
            Discovering       -> RouteHash.set ["discover"]
            ViewingFavourites -> RouteHash.set ["favourites"]
            Viewing story     -> RouteHash.set ["story", urliseStory story]
    else
        Nothing

urliseStory : Story -> String
urliseStory story = String.concat
    <| List.intersperse "-"
    <| String.split " " story.title
