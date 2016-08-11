module Splash (view) where

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
                img [src "images/splash-app-logo.png"] []
            ]
        ]
        , div [class "footer splash-footer"] [
            img [src "images/splash-site-logo.png"] []
        ]
    ]
