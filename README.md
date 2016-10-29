# elm-pouchdb

Native review request was posted on the 19 September 2016. Ref is [#200](https://github.com/elm-lang/package.elm-lang.org/issues/200) 

This library is a a set of [Elm](http://www.elm-lang.org/) modules that bind the functionalities of the great [pouchdb](https://pouchdb.com/) library. This library enables the user to use a [Couchdb](http://couchdb.apache.org/) or [pouchdb](https://pouchdb.com/) database. It is great tool for mobile-first applications, thanks to the powerful sync features of Couchdb-compatible databases.


It contains:
- **Pouchdb** A module for dealing with the creation of databases and standard operations like put, post, get, all_docs, queries and many more...
- **Change** An effect module that provides subscriptions for listening to document events within the databases.
- **Replicate** An effect module that provides subscriptions for replicating one database to the another.
- **Sync** An effect module that provides subscriptions for syncing one database to another.
-  **Events** An effect module that provides subscriptions for listening to database events.


This library was initially created by **Etienne Cavard** for **Oriata** and posted under **BSD3 license** on the 24 July 2016.


Thanks to the Pouchdb team and Elm-lang team for their respective work on the Javascript [pouchdb](https://pouchdb.com/) library and the [Elm](http://www.elm-lang.org/) language.


# Declaring Local and Remote Databases

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
# Put, Post, Get and All_docs, Query Operations on Databases

All these operations are implemented as Tasks. Below is an example for the **Put** operation:

```elm

    type Message = PutButton
                 | PutError Pouchdb.Fail
                 | PutSuccess Pouchdb.Put

    -- a bit of encoding
    encoder : String->String->Encode.Value
    encoder id val =
       Encode.object
          [ ("_id", Encode.string id)
          , ("val", Encode.string val)
          ]
    
    -- PutButton was sent by a button, see how a put task is now sent.
    
    update : Message -> Model -> (Model, Cmd Message)
    update msg model =
      case msg of
        PutButton->
          let 
            task = (Pouchdb.put model.localDb (encoder "id2" "hello") Nothing)
            cmd = Task.perform PutError PutSuccess task
          in
           (model,cmd)
        PutSuccess msg->
          let 
            newMsg = String.append "Successfully put in db with rev = " msg.rev
          in
            ({model|returnMsg=Just newMsg}, Cmd.none)
        PutError msg->
          let
            newMsg = String.append "Error putting in db with message = " msg.message
          in
           ({model|returnMsg=Just newMsg}, Cmd.none)
        
```


# Listening to Document Changes

Listening to document changes is done with a subscription mechanism:

```elm

    type Message = Change Change.ChangeEvent
                   | ...

    update : Message -> Model -> (Model, Cmd Message)
    update msg model =
      case msg of
        Change evt->
          case evt of
            Changed docValue ->
              ... some doc changes here
            Completed ->(model,Cmd.none)
            Error _ ->(model,Cmd.none)
        ...

    subscriptions : Model -> Sub Message
    subscriptions model =
      let
        options = Change.changeOptions
                  |> since Now
        
        change = Change.new "change1" model.localDb options Change
      in
      change
      
```



# Replicating Documents from one Database to Another

Replication is performed using a subscription mechanism:

```elm

    type Message = Replicate Replicate.ReplicateEvent
                    | ...
    
    
    type alias Model = { sourceDb : Pouchdb
                       , destDb : Pouchdb
                       ...
                       }
    ...

    update : Message -> Model -> (Model, Cmd Message)
    update msg model =
      case msg of
        Replicate evt->
          -- providing all cases here, for documentation only
          case evt of
            Replicate.Completed value->(model,Cmd.none)
            Replicate.Active value->(model,Cmd.none)
            Replicate.Paused value->(model,Cmd.none)
            Replicate.Changed value->(model,Cmd.none)
            Replicate.Denied value->(model,Cmd.none)
            Replicate.Error value->(model,Cmd.none)
        ...
    
    subscriptions : Model -> Sub Message
    subscriptions model =
      let
        replOpt = Replicate.defaultOptions
        
        replication = Replicate.new "replication" model.sourceDb model.destDb replOpt Replicate
        ...
      in
      Sub.batch [replication, ...]
      
```
