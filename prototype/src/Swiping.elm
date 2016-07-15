module Swiping (animate, itemSwipe, itemPos, swipeActions, swipeAction, swipePhotoAction, onSwipe, animateStep) where

import Json.Decode as Json exposing ((:=))
import Html exposing (Attribute)
import Html.Events exposing (on)
import Time exposing (Time)
import Easing exposing (..)
import Swipe exposing (..)
import Window

import Types exposing (..)

animate : Signal AppAction
animate = Signal.map2 Animate timeSoFar windowSize

animateStep : Time -> Window -> ItemPosition -> ItemPosition
animateStep t window state = case state of
    Leave pos -> Leaving window pos t (t+600) t
    Return pos -> Returning window pos t (t+600) t
    Leaving w pos start end _ ->
        Leaving window pos start end t
    Returning w pos start end _ ->
        Returning window pos start end t
    x -> x

sign : Float -> Float
sign number = abs number / number

timeSoFar : Signal Time
timeSoFar = Signal.foldp (+) 0 <| Time.fps 40

windowSize : Signal Window
windowSize = Signal.map2 (\w h -> {width = toFloat w, height = toFloat h})
    Window.width Window.height

itemSwipe : ItemPosition -> Maybe SwipeState
itemSwipe pos = case pos of
    Types.Swiping swipe -> Just swipe
    _ -> Nothing

itemPos : ItemPosition -> Maybe Float
itemPos pos = case pos of
    Types.Swiping (Swipe.Swiping swipe) -> Just <| swipe.x1 - swipe.x0
    Leave pos -> Just pos
    Return pos -> Just pos
    Leaving window pos start end t ->
        Just <| ease easeOutCubic float pos (window.width*sign pos) (end-start) (t-start)
    Returning window pos start end t ->
        Just <| ease easeOutCubic float pos 0 (end-start) (t-start)
    _ -> Nothing

swipeActions : Signal AppAction
swipeActions = Signal.map3
    (\w h -> swipeAction {width = toFloat w, height = toFloat h})
    Window.width Window.height
    swipes

swipeAction : Window -> Maybe SwipeState -> AppAction
swipeAction window swipe = case swipe of
    Just (End state) ->
        if abs (state.x1 - state.x0) > window.width/3 then
            MoveItem <| Leave <| state.x1 - state.x0
        else
            MoveItem <| Return <| state.x1 - state.x0
    Just swipe -> MoveItem <| Types.Swiping swipe
    Nothing -> NoAction
   
swipePhotoAction : Window -> Maybe SwipeState -> AppAction
swipePhotoAction window swipe = case swipe of
    Just (End state) ->
        if abs (state.x1 - state.x0) > window.width/3 then
            MovePhoto <| Leave <| state.x1 - state.x0
        else
            MovePhoto <| Return <| state.x1 - state.x0
    Just swipe -> MovePhoto <| Types.Swiping swipe
    Nothing -> NoAction
    
swipes : Signal (Maybe SwipeState)
swipes = Signal.map List.head swipeStates

onSwipe : Signal.Address a -> Maybe SwipeState -> (Window -> Maybe SwipeState -> a) -> List Attribute
onSwipe address swipeState swipeAction =
    let
        doAction touchState touchUpdate = Signal.message address
            <| swipeAction touchUpdate.window
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
            TouchStart -> Just <| Start
                { id = update.id
                , x = update.x
                , y = update.y
                , t0 = update.t0
                }
            TouchMove -> case swipe of
                Just (Start state) -> Just <| Swipe.Swiping
                    { x0 = state.x
                    , y0 = state.y
                    , x1 = update.x
                    , y1 = update.y
                    , id = state.id
                    , t0 = state.t0
                    , direction = Maybe.withDefault Right <| dir state.x state.y
                    }
                Just (Swipe.Swiping state) -> Just <| Swipe.Swiping
                    { x0 = state.x0
                    , y0 = state.y0
                    , x1 = update.x
                    , y1 = update.y
                    , id = state.id
                    , t0 = state.t0
                    , direction = Maybe.withDefault state.direction <| dir state.x0 state.y0
                    }
                _ -> Just <| Start
                    { id = update.id
                    , x = update.x
                    , y = update.y
                    , t0 = update.t0
                    }
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
                Just (Swipe.Swiping state) -> Just <| End
                    { x0 = state.x0
                    , y0 = state.y0
                    , x1 = update.x
                    , y1 = update.y
                    , id = state.id
                    , t0 = state.t0
                    , direction = Maybe.withDefault state.direction <| dir state.x0 state.y0
                    }
                _ -> Nothing

direction : Float -> Float -> Maybe Direction
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
    , x : Float
    , y : Float
    , t0 : Float
    , window : Window
    }

type TouchState = TouchStart | TouchMove | TouchEnd

touch : Json.Decoder SwipeUpdate
touch = Json.object3 (\t0 touch (width, height) -> {id = touch.id, x = touch.x, y = touch.y, t0 = toFloat t0, window = {width = toFloat width, height = toFloat height}})
    ("timeStamp" := Json.int)
    ("changedTouches" := Json.object1 (\x -> x)
        ("0" := changedTouch))
    ("view" := Json.object2 (\w h -> (w, h))
        ("innerWidth" := Json.int)
        ("innerHeight" := Json.int))

changedTouch = Json.object3 (\id x y -> {id = id, x = x, y = y})
    ("identifier" := Json.int)
    ("clientX" := Json.float)
    ("clientY" := Json.float)
