# Swipe Local History

## About
This app is designed to make local history and heritage more appealing.
We're doing this by focussing the content on stories and people instead of places and things.
And by bringing those elements to the front and center of the app.

The app is centered about swiping through interesting stories.
This allows those readers without any idea of their preferences to browse and let serendipity play a role in their interaction with heritage.

## Technical details
All of the code for this app can be found at https://github.com/CodeforAustralia/heritage-near-me/tree/master/swipe-local-history

The app is a single page HTML5 web app.
The front end of the app is powered by [Elm](http://elm-lang.org), a typed, functional language which compiles to JavaScript.
The back end is a [Postgres](http://www.postgresql.org) database with a [RESTful API](https://en.wikipedia.org/wiki/Representational_state_transfer) created by [Postgrest](http://postgrest.com).
The API and single page app are pulled together by an [Nginx](http://nginx.org/en/) server.

The front end code can be found [here](prototype).
The database schema can be found [here](backend/heritage-near-me.sql).
The documentation for the REST API can be found [here](http://postgrest.com/api/reading/).
The Nginx server config can be found [here](server/heritage-near-me).
