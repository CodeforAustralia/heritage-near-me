# Heritage Finder

Aka "OLD SKOOL FINDER" or "Old South Wales".

## About
This project is designed to make local history and heritage more appealing.
We're doing this by allowing users to swipe through interesting stories and people instead of places and things. This allows users to browse and let serendipity play a role in their interaction with heritage, making it accessible to more people.


## Technical details
The code for this project can be found at https://github.com/CodeforAustralia/heritage-near-me

The project presents a single page HTML5 web app.
The front end is powered by [Elm](http://elm-lang.org), a typed, functional language which compiles to JavaScript.
The back end is a [Postgres](http://www.postgresql.org) database with a [RESTful API](https://en.wikipedia.org/wiki/Representational_state_transfer) created by [Postgrest](http://postgrest.com).
The API and front end are pulled together by an [Nginx](http://nginx.org/en/) server.

The front end code can be found in the [prototype](prototype) directory.
The database schema can be found in [backend/](backend/heritage-near-me.sql).
The documentation for the REST API can be found [here](http://postgrest.com/api/reading/).
The Nginx server config can be found in [server/](server/heritage-near-me).


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
ln -s ~/your-user/path/to/heritage-near-me/server/heritage-near-me
```

The `root` directive of our nginx config says where to find the `prototype/` directory:

```
root /usr/local/var/nginx/hnm;
```

So set that up:

```
cd /usr/local/var/nginx/
ln -s ~/your-user/path/to/heritage-near-me/prototype hnm
```

`nginx` should be ready to go. Make sure `apache` is stopped if you have that on your dev machine (`sudo apachectl stop`) and start the server: `sudo nginx`. If you need to stop it later, run `sudo nginx -s stop`.

## Running PostgREST API as a service on Debian/Ubuntu

```
# prerequisite: postgrest binary from https://github.com/begriffs/postgrest/releases is installed as /usr/local/bin/postgrest, then:
cp server/postgrest-defaults /etc/defaults/postgrest
cp server/postgrest.init.d /etc/init.d/postgrest
sudo service postgrest start
```


## Updating Elm files


```
npm install -g elm@0.16
cd prototype && elm-package install && ./makeapp.sh
```



