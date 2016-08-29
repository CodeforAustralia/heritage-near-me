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

The front end code can be found in the [prototype](prototype) directory (for docs, start by reading `App.elm` and see [this issue](https://github.com/CodeforAustralia/heritage-near-me/issues/55).
The database schema can be found in [backend/hnm-tables.sql](backend/hnm-tables.sql) and [backend/hnm-views+functions.sql](backend/hnm-views+functions.sql).
The documentation for the REST API can be found [here](http://postgrest.com/api/reading/).
The Nginx server config can be found in [server/](server/heritage-near-me).


## Setup

Install database, API server, and web server. Using [brew](http://brew.sh/) on the command line, run:

```
brew install postgres postgis postgrest nginx
```

The output from the above command should say something about starting postgres and nginx, for example, you probably want to run this command next to make it so those two start when your computer does:

```
brew services start postgresql
brew services start nginx
```


Once PostgreSQL server is running, then import the required database:

```
cd backend
./dbinit.sh
```

(Need to wipe the database and restart? Run `backend/dbdrop.sh`.)


## Start the API server

```
backend/apistart.sh
```

(If that works, you should see something like "Listening on port 3000". Keep that running as long as you want the API server to run.)

## Start nginx

We use `nginx` so that requests to /api are rerouted to port 3000 where `postgrest`
is serving the API (see how that works by looking at the nginx config file `server/heritage-near-me`).

Add that config file to `nginx`'s config. For installs provided by `homebrew` on OSX, that means copying the file to (or linking to it from) the `/usr/local/etc/nginx/servers/` directory.

```
ln -s `pwd`/server/heritage-near-me /usr/local/etc/nginx/servers/heritage-near-me
```

The `root` directive of our nginx config says where to find the `prototype/` directory:

```
root /usr/local/var/nginx/hnm;
```

So set that up:

```
mkdir -p /usr/local/var/nginx
ln -s `pwd`/prototype /usr/local/var/nginx/hnm
```

Reload the nginx config:

```
nginx -s reload
````

nginx should now be running; open http://localhost:8088 in your web browser to confirm.

(Note, if that doesn't work you may need to make sure `apache` is stopped if you have that on your dev machine (`sudo apachectl stop`) and start the server: `sudo nginx`. If you need to stop it later, run `sudo nginx -s stop`).

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
cd prototype && elm-package install && make app
```
