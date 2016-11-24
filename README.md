# elm-pouchdb

Migrated to Elm 0.18 : Consequences are that elm-reactor no longer works with Pouchdb objects because Pouchdb objects cannot be displayed (crash!) in the debugger model window.
Please use another workflow, I've used gulp it's pretty easy to use.

Native review request was posted on the 2016-dec-09. Ref is [#200](https://github.com/elm-lang/package.elm-lang.org/issues/200) 

This library is a a set of [Elm](http://www.elm-lang.org/) modules that bind the functionalities of the great [pouchdb](https://pouchdb.com/) library. This library enables the user to use [Couchdb](http://couchdb.apache.org/)/[pouchdb](https://pouchdb.com/) database. It is great tool for mobile first applications, thanks to the powerfull sync feature of Couchdb comptatible databases.


It contains:
- **Pouchdb** module for dealing with the creation of databases and standard operations like put, post, get, all_docs and queries and many others...
- **Change** effect module that provides subscriptions for listening to document events within the databases.
- **Replicate** effect module that provides subscriptions for replicating one database to the another.
- **Sync** effect module that provides subscritions for syncing one database to another.
-  **Events** effect module that provides subscritions for listening to database events.


This library was initially created by **Etienne Cavard** for **Oriata** and posted under **BSD3 license** on the 24 july 2016.


Thanks to the Pouchdb team and Elm-lang team for their respective work on the js [pouchdb](https://pouchdb.com/) library and the [Elm](http://www.elm-lang.org/) language.


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
                 | Put (Result Pouchdb.Fail Pouchdb.Put)

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
        Put msg->
          let
            newMsg = unpack
                 (\m->String.append "Error putting in db with message = " m.message)
                 (\m->String.append "Successfully put in db with rev = " m.rev)
                  msg
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



# Replicating documents from one database to another

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