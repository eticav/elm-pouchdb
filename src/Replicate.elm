effect module Replicate where { subscription = MySub }
       exposing ( Options
                , defaultOptions
                , Since(Now,Seq)
                , ReplicateEvent( Completed
                                , Active
                                , Paused
                                , Changed
                                , Denied
                                , Error )
                , new
                , Filter (..)
                , BackOff
                , Live(..)
                , Tagger
                , SubId
                , live
                , since
                , batch_size               
                , heartbeat
                , timeout
                , batches_limit
                , filter)

{-| Replicate data from source to target. Replicate effects is a Pouchdb related modules. Its unique role is to provide a subscription mechanism to [Pouchdb](https://pouchdb.com/)[/CouchDB](http://couchdb.apache.org/) for your application. This library is to be used jointly with the Pouchdb library.

    type Message = Replicate Replicate.ReplicateEvent
                    | ...
    
    type alias DocModel = { id :String
                          , val : String }
        
    type alias Model = { sourceDb : Pouchdb
                       , destDb : Pouchdb
                       , docs : List DocModel
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


# Subscription definition
@docs new, Options, defaultOptions, ReplicateEvent, Since, Filter, BackOff, Live, Tagger, SubId
                

# Options Helper functions
@docs live, since, batch_size, heartbeat, timeout, batches_limit, filter

-}

import Native.Pouchdb exposing (..)
import Native.ElmPouchdbReplicate exposing (replicate)
  
import Task exposing (Task,map)
import Dict  exposing (Dict)
import Basics exposing (Never)
import Process exposing (spawn,kill)

import Json.Encode exposing (Value)
import Platform.Sub exposing (Sub)

import GenEffect exposing (..)
import Pouchdb exposing (Pouchdb)

{-| Represents the replication events emited from the database which can be any of 'Complete', 'Active', 'Paused', 'Change', 'Denied' and 'Error' events.
-}

type ReplicateEvent = Completed Value
                    | Active Value
                    | Paused Value
                    | Changed Value
                    | Denied Value
                    | Error Value
                      
type alias SubEvent = GenEffect.SubEvent ReplicateEvent

{-| Represents the subscription identifier
-}
type alias SubId = String
                 
type alias NativeStart = GenEffect.NativeStart ReplicateEvent


{-| Represents Tagger for declaring messages. Internal, only exposed here for reuse in module Sync 
-}
type alias Tagger msg = GenEffect.Tagger ReplicateEvent msg

{-| Represents a sequence related notion that specifies from when to start listening to the changes in the database. It is used within the Options.

    -- replicate from sequence number 500
    options = Replicate.defaultOptions
                  |> since Seq 500
        

-}
type Since = Now
           | Seq Int
             
             
{-| Represents the filtering options used for replication.

    -- replicate from a view
    options = Replicate.defaultOptions
                  |> filter (View "myview")


    --replicate from a filter 
    options = Replicate.defaultOptions
                  |> filter (Name "myfilter")


    --replicate from a function that returns a boolean
    --only declare the body of the function where doc is the parameter
    options = Replicate.defaultOptions
                  |> filter (Fun "{ return doc.type === 'marsupial'; }")

    --replicate within a list of docIds
    options = Replicate.defaultOptions
                  |> filter (Ids ["id1","id2"])

-}                     
type Filter = View String
            | Name String
            | Fun String
            | Ids (List Pouchdb.DocId)
            | NoFilter
             
{-| Backoff function to be used in retry replication. This is a function that takes the current backoff as input (or 0 the first time) and returns a new backoff in milliseconds. You can use this to tweak when and how replication will try to reconnect to a remote database when the user goes offline. Defaults to a function that chooses a random backoff between 0 and 2 seconds and doubles every time it fails to connect. The default delay will never exceed 10 minutes. 
-}

type alias BackOff = Maybe String

{-| Represents the application will retry to replicate in case of failure. If NoLive then  replication does not concern any future events. If NoRetry, future events are also concerned, but in case of failure the application will not retry to replicate. Retry option wioll retyr to replicate in case of failure, it may accompanied by a Backoff function.
-}
type Live = NoRetry
          | Retry BackOff
          | NoLive

{-| Represents all the options that can be used to replicate one database to another
-}
type alias Options = { live : Live 
                     , filter : Filter
                     --, query_params : List QueryParam TODO
                     , since : Since
                     , heartbeat  : Maybe Int
                     , timeout : Maybe Int
                     , batch_size : Maybe Int
                     , batches_limit : Maybe Int }


{-| Use defaultOptions to create the default [Options](#Options) and chain with helper setting functions.
-}                               
defaultOptions : Options
defaultOptions = { live = Retry Nothing
                 , filter = NoFilter
                 --, query_params = [] TODO
                 , since = Seq 0
                 , heartbeat  = Nothing
                 , timeout = Nothing
                 , batch_size = Nothing
                 , batches_limit = Nothing }

{-| Represents a helper function to set live. Can be chained to other helper functions.
-}
live : Live->Options->Options
live val options =
  { options | live =  val}

{-| Represents a helper function to set filter. Can be chained to other helper functions.
-}
filter : Filter->Options->Options
filter val options =
  { options | filter =  val}

  
{-| Represents a helper function to set since. Can be chained to other helper functions.
-}
since : Since->Options->Options
since val options =
  { options | since = val}


{-| Represents a helper function to set heartbeat. Can be chained to other helper functions.
-}
heartbeat : Int->Options->Options
heartbeat val options =
  { options | heartbeat = Just val}

    
{-| Represents a helper function to set timeout. Can be chained to other helper functions.
-}
timeout : Int->Options->Options
timeout val options =
  { options | timeout = Just val}

  
{-| Represents a helper function to set batch_size. Can be chained to other helper functions.
-}
batch_size : Int->Options->Options
batch_size val options =
  { options | batch_size = Just val}

    
{-| Represents a helper function to set batches_limit. Can be chained to other helper functions.
-}
batches_limit : Int->Options->Options
batches_limit val options =
  { options | batches_limit = Just val}

    
{- Represents a helper function to set query_params. Can be chained to other helper functions.

query_params : List QueryParam->Options->Options
query_params val options =
  { options | query_params =  val}
-}


  
{-| Creates a new replication subscrition to the Pouchdb database.

    type Message = Replicate Replicate.ReplicateEvent
                 | ...

    subscriptions : Model -> Sub Message
    subscriptions model =
      let
        ...
    
        replOpt = Replicate.defaultOptions
        
        replication = Replicate.new "replication" model.sourceDb model.destDb replOpt Replicate
      in
      Sub.batch [replication, ...]

-}
new : SubId->Pouchdb->Pouchdb->Options->(Tagger msg)->Sub msg
new id source target opt tagger =
  subscription ( Replicate { id=id
                           , native=Native.ElmPouchdbReplicate.replicate source target opt
                           , tagger = tagger
                        }
               )

type alias ReplicateType msg =  GenEffect.ChangeType ReplicateEvent msg

type MySub msg = Replicate (ReplicateType msg)

type alias Process msg = GenEffect.Process ReplicateEvent msg
   
type alias Processes msg =
  Dict.Dict SubId (Process msg)

type alias State msg = { 
    processes : Processes msg
  }

subMap : (a -> b)
       -> MySub a
       -> MySub b
subMap f (Replicate mySub) =
  Replicate (GenEffect.subMap f mySub) 

init : Task Never (State msg)
init = GenEffect.init


onEffects : Platform.Router msg msg ->
            List (MySub msg) ->
            {b|processes:Processes msg}->
            Task Never (State msg)
onEffects router subs state = GenEffect.onEffects (\x-> case x of Replicate replicateType -> replicateType) router subs state
      
onSelfMsg : Platform.Router msg msg ->
            msg ->
            State msg ->
            Task Never (State msg)
onSelfMsg =
  GenEffect.onSelfMsg
