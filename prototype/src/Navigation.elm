module Navigation (navigation) where

import Html exposing (Html, div, nav, h1, img, button, a, i, text)
import Html.Attributes exposing (class, src, href)
import Html.Events exposing (onClick)

import Types exposing (..)

{-| The top level navigation view for the app -}
navigation : Signal.Address AppAction -> AppLocation -> Html
navigation address location =
    nav [class "navigation"] [ buttonHtml address location, titleHtml location]



{-| Generate the title of the nav bar, which may vary depending on the screen -}
titleHtml : AppLocation -> Html
titleHtml location =
    let
        container = div [class "navigation-center"]
    in
        case location of

            Discovering ->
                container [logoDiv]

            Viewing _ _ _ ->
                container [logoDiv]

            ViewingFavourites ->
                container [h1 [] [text "Favourites"]]

logoDiv = div [class "logo"] [a [href "/"] [img [src "images/logo.png"] []]]


{-| Generate the top button on the nav bar, which may vary depending on the screen. -}
buttonHtml : Signal.Address AppAction -> AppLocation -> Html
buttonHtml address location =
    case location of

        Discovering ->
            button [onClick address ViewFavourites] [i [class "fa fa-heart fa-2x"] []]

        Viewing _ _ _ ->
            button [onClick address Back] [i [class "fa fa-angle-left fa-3x"] []]

        ViewingFavourites ->
             button [onClick address Discover] [i [class "fa fa-map fa-2x"] []]

