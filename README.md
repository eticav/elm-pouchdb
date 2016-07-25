# elm-pouchdb

This library is a a set of Elm modules that bind the functionalities of the great pouchdb library.


It contains:
- **Pouchdb** module for dealing with the creation of databases and standard operations like put, post, get, all_docs and queries and many others...
- **Change** effect module that provides subscriptions for listening to document events within the databases.
- **Replicate** effect module that provides subscriptions for replicating one database to the another.
- **Sync** effect module that provides subscritions for syncing one database to another.
-  **Events** effect module that provides subscritions for listening to database events.


Any helpfull contributions from any contributors are all welcome.


This library was initially created by **Etienne Cavard** for **Oriata** and posted under **BSD3 license** on the 24 july 2016.


Thanks to the Pouchdb team and Elm-lang team for their respective work on the js Pouchdb library and the Elm language.


# Declaring local and remote database

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
# Put, Post, Get and All_docs, Query Operations on databases

All these oprations are implemented as Tasks. Below is an example for the **Put** Operation.

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
    
    -- PutButton was sent by a button, see how a put task is now send.
    
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


# Listening to document changes

Listening to document changes is done with a subscription mecanism

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



# Replicating docments from one database to another

Replication is done with a subscription mecanism

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