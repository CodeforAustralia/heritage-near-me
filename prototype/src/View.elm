module View (view) where

{-| The module provides the main view for the app.

@docs view

-}

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
    Viewing storyId itemView storyScreen -> div [class <| "app story-screen " ++ storyScreenClass storyScreen]
        [ navigation address app.location
        , Story.view address (Data.getItem storyId app) itemView storyScreen
        ]
    ViewingFavourites -> div [class "app favourites-screen"]
        [ navigation address app.location
        , Favourites.view address
            <| List.filterMap Remote.Data.get
            <| List.map (\id -> Data.getItem id app)
            <| app.discovery.favourites
        ]

{-| The CSS class name for a story screen

    storyScreenClass Intro = "story-intro"
    storyScreenClass Intro = "story-body"
 -}
storyScreenClass : StoryScreen -> String
storyScreenClass screen =
    case screen of
        Intro ->
            "story-intro"
        Body ->
            "story-body"

