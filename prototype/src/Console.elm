module Console (log) where


{-| The Console module provides console debug logging.

Under the hood, it just calls Debug.log, but lets us quickly disable that.

# Console logging

@docs log

-}

log : String -> a -> a
log msg a =
    let
        enabled = False -- set to False to disable logging
    in
        if enabled then
            Debug.log msg a
        else
            a
