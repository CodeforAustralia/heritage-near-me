module Swiping (swipeActions, swipeAction, onSwipe) where

import Json.Decode as Json exposing ((:=))
import Html exposing (Attribute)
import Html.Events exposing (on)
import Swipe exposing (..)

import Types exposing (..)

swipeActions : Signal (Action a)
swipeActions = Signal.map swipeAction swipes

swipeAction : Maybe SwipeState -> Action a
swipeAction swipe = case swipe of
    Just (End state) -> case state.direction of
        Right -> Favourite
        Left -> Pass
        _ -> SwipingItem Nothing
    swipe -> SwipingItem swipe
    
swipes : Signal (Maybe SwipeState)
swipes = Signal.map List.head swipeStates


onSwipe : Signal.Address a -> Maybe SwipeState -> (Maybe SwipeState -> a) -> List Attribute
onSwipe address swipeState swipeAction =
    let
        doAction touchState touchUpdate = Signal.message address
            <| swipeAction
            <| updateSwipeState swipeState touchState touchUpdate
    in
        [ on "touchstart" touch <| doAction TouchStart
        , on "touchmove" touch <| doAction TouchMove
        , on "touchend" touch <| doAction TouchEnd
        ]

updateSwipeState : Maybe SwipeState -> TouchState -> SwipeUpdate -> Maybe SwipeState
updateSwipeState swipe touch update = let
        dir x y = direction (update.x - x) (update.y - y)
    in
        case touch of
            TouchStart -> Just <| Start update
            TouchMove -> case swipe of
                Just (Start state) -> Just <| Swiping
                    { x0 = state.x
                    , y0 = state.y
                    , x1 = update.x
                    , y1 = update.y
                    , id = state.id
                    , t0 = state.t0
                    , direction = Maybe.withDefault Right <| dir state.x state.y
                    }
                Just (Swiping state) -> Just <| Swiping
                    { x0 = state.x0
                    , y0 = state.y0
                    , x1 = update.x
                    , y1 = update.y
                    , id = state.id
                    , t0 = state.t0
                    , direction = Maybe.withDefault state.direction <| dir state.x0 state.y0
                    }
                _ -> Just <| Start update
            TouchEnd -> case swipe of
                Just (Start state) -> Just <| End
                    { x0 = state.x
                    , y0 = state.y
                    , x1 = update.x
                    , y1 = update.y
                    , id = state.id
                    , t0 = state.t0
                    , direction = Maybe.withDefault Right <| dir state.x state.y
                    }
                Just (Swiping state) -> Just <| End
                    { x0 = state.x0
                    , y0 = state.y0
                    , x1 = update.x
                    , y1 = update.y
                    , id = state.id
                    , t0 = state.t0
                    , direction = Maybe.withDefault state.direction <| dir state.x0 state.y0
                    }
                _ -> Nothing

direction : Int -> Int -> Maybe Direction
direction dx dy =
    if abs dx > abs dy then
        if dx > 0 then
            Just Right
        else if dx < 0 then
            Just Left
        else
            Nothing
    else
        if dy > 0 then
            Just Down
        else if dy < 0 then
            Just Up
        else
            Nothing

type alias SwipeUpdate =
    { id : Int
    , x : Int
    , y : Int
    , t0 : Float
    }

type TouchState = TouchStart | TouchMove | TouchEnd

touch : Json.Decoder SwipeUpdate
touch = Json.object2 (\t0 touch -> {id = touch.id, x = floor touch.x, y = floor touch.y, t0 = toFloat t0})
    ("timeStamp" := Json.int)
    ("changedTouches" := Json.object1 (\x -> x)
        ("0" := changedTouch))

changedTouch = Json.object3 (\id x y -> {id = id, x = x, y = y})
    ("identifier" := Json.int)
    ("clientX" := Json.float)
    ("clientY" := Json.float)
