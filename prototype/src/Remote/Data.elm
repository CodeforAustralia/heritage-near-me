module Remote.Data (RemoteData(..), get, map, isLoading, isLoaded, isFailed) where

import Http

{-| The Remote Data module helps organise the management remote data

# Data

@docs RemoteData

@docs get, map

@docs isLoading, isLoaded, isFailed

# Data Storage

@docs empty, update

-}

{-| Remote data has three states.

It can be loading, and then either have loaded or failed to load

-}
type RemoteData a = Loading | Loaded a | Failed Http.Error

{-| Get the remote data value if it is loaded -}
get : RemoteData a -> Maybe a
get data = case data of
    Loaded x -> Just x
    _ -> Nothing

{-| Apply a function to loaded remote data -}
map : (a -> b) -> RemoteData a -> RemoteData b
map f data = case data of
    Loaded x -> f x |> Loaded
    Failed err -> Failed err
    Loading -> Loading

{-| Is the asset still loading? -}
isLoading : RemoteData a -> Bool
isLoading data = case data of
    Loading -> True
    _ -> False

{-| Did the data load succesfully? -}
isLoaded : RemoteData a -> Bool
isLoaded data = case data of
    Loaded _ -> True
    _ -> False

{-| Did the data fail to load? -}
isFailed : RemoteData a -> Bool
isFailed data = case data of
    Failed _ -> True
    _ -> False
