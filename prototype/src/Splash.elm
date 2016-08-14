module Splash (view, loader) where

import Html exposing (Html, div, img)
import Html.Attributes exposing (class, src)

{-| The main HTML view for splash page  -}
view : Html
view =
    div [class "splash-screen"] [
        div [class "splash-background"] []
        , div [class "splash-content"] [
            div [class "splash-hero-image"] [
              img [src "images/splash-hero-image.png"] []
            ]
            , div [class "splash-app-logo"] [
                img [src "images/logo.png"] []
            ]
        ]
        , div [class "loader"] [loader]
        , div [class "footer splash-footer"] [
            img [src "images/splash-site-logo.png"] []
        ]
    ]

{-| Loading animation.

See https://connoratherton.com/loaders
-}
loader : Html
loader = ballScaleMultiple


ballScaleMultiple : Html
ballScaleMultiple =
 div [class "loader-inner-xx ball-scale-multiple"] [
          div [] []
        , div [] []
        , div [] []
    ]

pacman : Html
pacman =
    div [class "loader-inner pacman"] [
          div [] []
        , div [] []
        , div [] []
        , div [] []
        , div [] []
    ]