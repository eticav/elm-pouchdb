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
                , Filter
                , BackOff
                , Live
                , Tagger
                , SubId)
         
{- Replicate data from source to target. Replicate effects is a Pouchdb related modules. Its unique role is to provide a subscription mechanism to [Pouchdb](https://pouchdb.com/)[/CouchDB](http://couchdb.apache.org/) for your application. This library is to be used jointly with the Pouchdb library.

# Definition
@docs now, Options, ReplicateEvent, Since


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

{- Represents the replication events emited from the database which can be any of 'Complete', 'Active', 'Paused', 'Change', 'Denied' and 'Error' events.
-}

type ReplicateEvent = Completed Value
                    | Active Value
                    | Paused Value
                    | Changed Value
                    | Denied Value
                    | Error Value
                      
type alias SubEvent = GenEffect.SubEvent ReplicateEvent
              
type alias SubId = String
                 
type alias NativeStart = GenEffect.NativeStart ReplicateEvent

type alias Tagger msg = GenEffect.Tagger ReplicateEvent msg

{- Represents a sequence related notion that specifies from when to start listening to the changes in the database. Replicate changes after the given sequence number or start from Now.
-}
                      
type Since = Now
           | Seq Int
             
{- Represents the filtering options used for replication. 
-}
                      
type Filter = View String
            | Name String
            | Fun String
            | NoFilter
             
{- Backoff function to be used in retry replication. This is a function that takes the current backoff as input (or 0 the first time) and returns a new backoff in milliseconds. You can use this to tweak when and how replication will try to reconnect to a remote database when the user goes offline. Defaults to a function that chooses a random backoff between 0 and 2 seconds and doubles every time it fails to connect. The default delay will never exceed 10 minutes. 
-}

type alias BackOff = Maybe String

type Live = NoRetry
          | Retry BackOff
          | NoLive


type alias Options = { live : Live 
                     , filter : Filter
                     , doc_ids : Maybe Bool
                     , query_params : Maybe Value
                     , since : Since
                     , heartbeat  : Maybe Bool
                     , timeout : Maybe Bool
                     , batch_size : Maybe Bool
                     , batches_limit : Maybe Bool }
                                                
defaultOptions : Options
defaultOptions = { live = Retry Nothing
                 , filter = NoFilter
                 , doc_ids = Nothing
                 , query_params = Nothing
                 , since = Seq 0
                 , heartbeat  = Nothing
                 , timeout = Nothing
                 , batch_size = Nothing
                 , batches_limit = Nothing } 
                                  
{- Creates a new replication subscrition to the Pouchdb database.
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
