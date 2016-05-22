# Heritage Finder

Aka "OLD SKOOL FINDER" or "Old South Wales".

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


## Setup

Install database, API server, and web server.

```
brew install postgres postgrest nginx
```

Make sure PostgreSQL server is running and then import the required database:

```
cd backend
./dbinit.sh
```

(Need to wipe the database and restart? Run `backend/dbdrop.sh`.)


## Start the API server

```
backend/apistart.sh
```

## Start nginx

We use `nginx` so that requests to /api are rerouted to port 3000 where `postgrest`
is serving the API (see how that works by looking at the nginx config file `server/heritage-near-me`).

Add that config file to `nginx`'s config. For installs provided by `homebrew` on OSX, that means copying the file to (or linking to it from) the `/usr/local/etc/nginx/servers/` directory.

```
cd /usr/local/etc/nginx/servers/
ln -s ~/your-user/path/to/heritage-near-me/swipe-local-history/server/heritage-near-me
```

The `root` directive of our nginx config says where to find the `prototype/` directory:

```
root /usr/local/var/nginx/hnm;
```

So set that up:

```
cd /usr/local/var/nginx/
ln -s ~/your-user/path/to/heritage-near-me/swipe-local-history/prototype hnm
```

`nginx` should be ready to go. Make sure `apache` is stopped if you have that on your dev machine (`sudo apachectl stop`) and start the server: `sudo nginx`. If you need to stop it later, run `sudo nginx -s stop`.




