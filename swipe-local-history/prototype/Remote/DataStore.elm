module Remote.DataStore (RemoteDataStore(..), empty, update, get, loaded, fetch, fetchInsert) where

import Dict exposing (Dict)
import Http
import Task exposing (Task)
import Effects

import Remote.Data exposing (RemoteData(..), isLoading, isLoaded, isFailed)

{-| The Romote Data Store module helps store remotely fetched data

# Data Store

@docs RemoteDataStore, empty, update, get, loaded

## Fetch data
@docs fetch, fetchInsert

@docs fetchMany, fetchInsertMany

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
    -> Task Effects.Never (RemoteDataStore id v -> RemoteDataStore id v)
fetch id request alter =
        request id
    `Task.andThen`
        (\value -> update id (alter <| Loaded value) |> Task.succeed)
    `Task.onError`
        (\error -> update id (alter <| Failed error) |> Task.succeed)

{-| Fetches remote data and if the data was successfully loaded,
it over writes any old data with the same id
-}
fetchInsert : id
    -> (id -> Task Http.Error v)
    -> Task Effects.Never (RemoteDataStore id v -> RemoteDataStore id v)
fetchInsert id request =
    fetch id request updateIfLoaded

{-| Compares old and new loaded data and returns loaded data if it exists
otherwise it returns the newest error
-}
updateIfLoaded : RemoteData v -> Maybe (RemoteData v) -> Maybe (RemoteData v)
updateIfLoaded newValue oldValue =
    if isLoaded newValue then
        Just newValue
    else if Maybe.map isFailed oldValue |> Maybe.withDefault False then
        Just newValue
    else
        oldValue
