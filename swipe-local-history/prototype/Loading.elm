module Loading (loading) where

import Html exposing (Html, div, i)
import Html.Attributes as Attr exposing (..)
import Swipe exposing (SwipeState(..))

{-| Html view for loading placeholder -}
loading : Html
loading = div [class "loading"]
    [ i [class "fa fa-circle-o-notch fa-spin fa-3x"] [] ]
