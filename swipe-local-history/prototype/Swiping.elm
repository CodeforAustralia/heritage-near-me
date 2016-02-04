module Swiping (swipeActions) where

import Swipe exposing (..)

import Types exposing (..)

swipeActions : Signal (Action a)
swipeActions = Signal.filterMap swipeAction NoAction swipes

swipeAction : Maybe SwipeState -> Maybe (Action a)
swipeAction swipe = case swipe of
    Just (Start state) -> Nothing
    Just (Swiping state) -> Just <| SwipingItem (state.x1 - state.x0)
    Just (End state) -> case state.direction of
        Right -> Just Favourite
        Left -> Just Pass
        _ -> Nothing
    Nothing -> Nothing
    
swipes : Signal (Maybe SwipeState)
swipes = Signal.map List.head swipeStates
