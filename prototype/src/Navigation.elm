module Navigation (navigation) where

import Html exposing (Html, div, span, nav, h1, img, button, a, i, text)
import Html.Attributes exposing (class, src, href)
import Html.Events exposing (onClick)

import Types exposing (..)

{-| The top level navigation view for the app -}
navigation : Signal.Address AppAction -> AppLocation -> Html
navigation address location =
    let
        -- define some html components
        goBackButton = button [onClick address Back] [i [class "fa fa-angle-left fa-3x"] []]
        goDiscoverButton = button [onClick address Discover] [i [class "fa fa-compass fa-2x"] []]
        goMapButton = button [onClick address ViewMapScreen] [i [class "fa fa-map fa-2x"] []]
        goFavsButton = button [onClick address ViewFavourites] [i [class "fa fa-heart fa-2x"] []]
        goSearchButton = button [onClick address ViewSearchScreen] [i [class "fa fa-search fa-2x"] []]
        logoDiv = div [class "logo"] [a [href "/"] [img [src "images/logo.png"] []]]
        navTitle title = h1 [] [text title]
        noNavBar = text ""
    in
        -- produce a different nav bar for every AppLocation
        case location of

            SplashPage -> noNavBar

            AboutScreen -> navBarHtml
                { side1 = [goBackButton]
                , center = [navTitle "About"]
                , side2 = []
                }

            Viewing _ _ _ -> navBarHtml
                { side1 = [goBackButton]
                , center = [logoDiv]
                , side2 = []
                }

            ViewingFavourites -> navBarHtml
                { side1 = [goBackButton]
                , center = [navTitle "Favourites"]
                , side2 = []
                }

            Discovering -> navBarHtml
                { side1 = []
                , center = [logoDiv]
                , side2 =
                    [ goMapButton
                    , goSearchButton
                    , goFavsButton ]
                }

            MapScreen -> navBarHtml
                { side1 = []
                , center = [logoDiv]
                , side2 =
                    [ goDiscoverButton
                    , goSearchButton
                    , goFavsButton
                    ]
                }

            SearchScreen -> navBarHtml
                { side1 = []
                , center = [logoDiv]
                , side2 =
                    [ goDiscoverButton
                    , goSearchButton
                    , goFavsButton
                    ]
                }

type alias NavBarElements =
    { side1 : List Html
    , center : List Html
    , side2 : List Html
    }

navBarHtml : NavBarElements -> Html
navBarHtml bar =
    nav [class "navigation"]
        [ div [class "navigation-side1"] bar.side1
        , div [class "navigation-center"] bar.center
        , div [class "navigation-side2"] bar.side2
        ]
