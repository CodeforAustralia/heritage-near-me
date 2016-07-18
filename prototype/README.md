# A few notes on developing the prototype code

This is coded in the [Elm language](elm-lang.org). They have good [docs](http://elm-lang.org/docs) - start by learning the [Syntax](http://elm-lang.org/docs/syntax) and perusing the [guide](http://guide.elm-lang.org/).



## IDE support

Using Sublime editor? You'll want these:

* General lanugage support: https://packagecontrol.io/packages/Elm%20Language%20Support
* Highlight build errors: https://packagecontrol.io/packages/Highlight%20Build%20Errors
* Elm oracle (can be used on command line, but also helps Sublime show you function documentation): https://github.com/ElmCast/elm-oracle

Using Atom? Try [reading this](https://boonofcode.svbtle.com/setting-up-an-atom-elm-dev-environment). Using Emacs? Try [this](https://github.com/jcollard/elm-mode). Looks like there's good [Light Table](http://lighttable.com/) [support](https://www.youtube.com/watch?v=B_eZw_GcM-4) too.


## Debugging tips

1. Trying to figure out the type of something?

Pass it to a function that takes a different type.

For example, say we're trying to figure out what the heck the type of this code is:

```
List.foldl update_ dataStore stories
```

So we'll make a little function that takes a type we'll never actually use:

```
    type Nada = Zilch

    gimmeType: Nada -> Nada
    gimmeType nada = Zilch
```

Then pass the troublesome code into our function:

```
    ...
    gimmeType (List.foldl update_ dataStore stories)
    ...
```

which will cause a compiler error with a helpful message explaining the type:

```
prototype(master)$ make app
-- TYPE MISMATCH --------------------------------------------------- src/App.elm

The argument to function `gimmeType` is causing a mismatch.

372│                      gimmeType (List.foldl update_ dataStore stories)
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Function `gimmeType` is expecting the argument to be:

    Nada

But it is:

    RemoteDataStore StoryId Story

```

2. Get a debug log in browser console.

Use the Debug.log function.

For example, you might change your `update` function to debug the `action`s we
generate.

```
    ...
    case action |> Debug.log "action" of
    ...
```
