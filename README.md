# elm-pouchdb

This library is a a set of Elm modules that bind the functionalities of the great pouchdb library.


It contains:
- **Pouchdb** for dealing with the creation of databases and standard operations like put, post, get, all_docs and queries and many others...
- **Change** effect module that provides subscriptions for listening to document events within the databases.
- **Replicate** effect module that provides subscriptions for replicating one database to the another.
- **Sync** effect module that provides subscritions for syncing one database to another.
-  **Events** effect module that provides subscritions for listening to database events.


Any helpfull contributions from any contributors are all welcome.


This library was initially created by **Etienne Cavard** for **Oriata** and posted under **BSD3 license** on the 24 july 2016.


Thanks to the Pouchdb team and Elm-lang team for their respective work on the js Pouchdb library and the Elm language.


# declaring local and remote database

```elm

    type alias Model =
      { local : Pouchdb
      , remote : Pouchdb
      }
    
    initialModel : Model
    initialModel =
      let
        local = db "DB-Test" dbOptions
        remote = db "https://xxxxxx.cloudant.com/db-test"
          (dbOptions
            |> auth "myUserName" "myPassword"
            |> ajaxCache True)
      in 
        { local = local
        , remote = remote
        }
        
```

# listening to document changes

subscriptions : Model -> Sub Message
    subscriptions model =
      let
        options = Change.changeOptions
                  |> since Now
        
        change = Change.new "change1" model.localDb options Change
      in
      change