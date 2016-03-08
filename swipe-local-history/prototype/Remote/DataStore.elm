module Remote.DataStore (RemoteDataStore(..), empty, update, get, loaded, fetch, fetchInsert) where

import Dict exposing (Dict)
import Http
import Task exposing (Task)

import Remote.Data exposing (RemoteData(..))

{-| The Romote Data Store module helps store remotely fetched data

# Data Store

@docs RemoteDataStore, empty, update, get, loaded

## Fetch data
@docs fetch, fetchInsert

-}

{-| A datastore linking remote requests to remote data -}
type RemoteDataStore id v = RemoteDataStore (Dict String (RemoteData v))

{-| Create an empty data store -}
empty : RemoteDataStore id v
empty = RemoteDataStore <| Dict.empty

{-| Update the value in the data store -}
update : id
    -> (Maybe (RemoteData v) -> Maybe (RemoteData v))
    -> RemoteDataStore id v
    -> RemoteDataStore id v
update id alter (RemoteDataStore store) = RemoteDataStore
    <| Dict.update (toString id) alter store

{-| Get a value from the data store -}
get : id
    -> RemoteDataStore id v
    -> RemoteData v
get id (RemoteDataStore store) = Maybe.withDefault Loading
    <| Dict.get (toString id) store

{-| Get all loaded values -}
loaded : RemoteDataStore id v
    -> List v
loaded (RemoteDataStore store) = Dict.values store
    |> List.filterMap Remote.Data.get

{-| Fetch remote data and update the data store

The third argument to this function is a function that
takes the fetched value, any value fetched previously with the same id,
and returns the value which should be stored.
-}
fetch : id
    -> (id -> Task Http.Error v)
    -> (RemoteData v -> Maybe (RemoteData v) -> Maybe (RemoteData v))
    -> RemoteDataStore id v
    -> Task () (RemoteDataStore id v)
fetch id request alter store =
        request id
    `Task.andThen`
        (\value -> update id (alter <| Loaded value) store |> Task.succeed)
    `Task.onError`
        (\error -> update id (alter <| Failed error) store |> Task.succeed)

{-| Fetches remote data and over writes any old data with the same id -}
fetchInsert : id
    -> (id -> Task Http.Error v)
    -> RemoteDataStore id v
    -> Task () (RemoteDataStore id v)
fetchInsert id request store =
    fetch id request (\newValue oldValue -> Just newValue) store
