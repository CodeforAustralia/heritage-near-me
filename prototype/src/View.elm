module View (view) where

import Html exposing (Html, div, nav, img, button, a, i, text)
import Html.Attributes exposing (class, src, href)
import Html.Events exposing (onClick)

import Types exposing (..)
import Remote.Data
import Data
import Navigation exposing (navigation)
import Discover
import Story
import Favourites 


{-| The main view for the app.
It takes the location from the app state and turns it into the view of the app.
It also passes the address for UI actions (such as clicking and swiping) to the sub views.
-}
view : Signal.Address AppAction -> AppModel -> Html
view address app = case app.location of
    Discovering -> Discover.view address app
        <| navigation address app.location
    Viewing storyId itemView -> div [class "app"]
        [ navigation address app.location
        , Story.view address (Data.getItem storyId app) itemView
        ]
    ViewingFavourites -> div [class "app"]
        [ navigation address app.location
        , Favourites.view address
            <| List.filterMap Remote.Data.get
            <| List.map (\id -> Data.getItem id app)
            <| app.discovery.favourites
        ]


