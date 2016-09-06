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
import Splash
import About
import Navigation exposing (navigation)
import Discover
import Story
import Favourites
import Console


{-| The main view for the app.
It takes the location from the app state and turns it into the view of the app.
It also passes the address for UI actions (such as clicking and swiping) to the sub views.
-}
view : Signal.Address AppAction -> AppModel -> Html
view address app =
    let
        _ = Console.log "Viewing location" app.location
        content = screenView address app
    in
        div [class "app screen-size"] [content]


{-| Get view for a single screen -}
screenView : Signal.Address AppAction -> AppModel -> Html
screenView address app = case app.location of

    SplashPage -> Splash.view

    MapScreen -> div [class "map-screen"]
        [ navigation address app.location ]

    SearchScreen -> div [class "search-screen"]
        [ navigation address app.location ]

    AboutScreen -> div [class "about-screen"]
        [ navigation address app.location
        , About.view
        ]

    Discovering -> Discover.view address app
        <| navigation address app.location

    Viewing storyId itemView storyScreen -> div [class <| "story-screen " ++ storyScreenClass storyScreen]
        [ navigation address app.location
        , Story.view address (Data.getItem storyId app) itemView storyScreen
        ]

    ViewingFavourites -> div [class "favourites-screen"]
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
        MoreInfo ->
            "story-more-info"

