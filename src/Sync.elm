effect module Sync where { subscription = MySub }
       exposing (new)
         
{-| Synchronise data between source and target. Sync effects is a Pouchdb related module. Its unique role is to provide a subscription mechanism to [Pouchdb](https://pouchdb.com/)[/CouchDB](http://couchdb.apache.org/) for your application. This library is to be used jointly with the Pouchdb library.

@docs new
-}

import Native.Pouchdb exposing (..)
import Native.ElmPouchdbReplicate exposing (sync)
import Replicate exposing (ReplicateEvent
                          , Since
                          , Filter
                          , Live
                          , BackOff
                          , Options
                          , Tagger
                          , SubId) 
import Task exposing (Task,map)
import Dict  exposing (Dict)
import Basics exposing (Never)
import Process exposing (spawn,kill)

import Json.Encode exposing (Value)
import Platform.Sub exposing (Sub)

import GenEffect exposing (ChangeType
                          , Process
                          , onSelfMsg
                          , onEffects
                          , init
                          , subMap)
import Pouchdb exposing (Pouchdb)

{-| Creates a new sync subscrition to the Pouchdb database. Its syntatic sugar for a bi-directional replication. Therfore S1ync.new reusses Options and ReplicateEvent from Replicate module. Check the Replicate documentation for more details.

    type Message = Sync Replicate.ReplicateEvent
                 | ...

    subscriptions : Model -> Sub Message
    subscriptions model =
      let
        ...
    
        pushOpt = Replicate.defaultOptions
        pullOpt = Replicate.defaultOptions

        sync = Sync.new "sync1" model.sourceDb model.destDb pushOpt pullOpt Sync
      in
      Sub.batch [sync, ...]
-}

new : SubId->Pouchdb->Pouchdb->Options->Options->(Tagger msg)->Sub msg
new id source target pushOpt pullOpt tagger =
  subscription ( Sync { id=id
                      , native=Native.ElmPouchdbReplicate.sync source target pushOpt pullOpt
                      , tagger = tagger
                      }
               )

type alias SyncType msg =  GenEffect.ChangeType ReplicateEvent msg

type MySub msg = Sync (SyncType msg)

type alias Process msg = GenEffect.Process ReplicateEvent msg
   
type alias Processes msg =
  Dict.Dict SubId (Process msg)

type alias State msg = { 
    processes : Processes msg
  }

subMap : (a -> b)
       -> MySub a
       -> MySub b
subMap f (Sync mySub) =
  Sync (GenEffect.subMap f mySub) 

init : Task Never (State msg)
init = GenEffect.init


onEffects : Platform.Router msg msg ->
            List (MySub msg) ->
            {b|processes:Processes msg}->
            Task Never (State msg)
onEffects router subs state = GenEffect.onEffects (\x-> case x of Sync syncType -> syncType) router subs state
      
onSelfMsg : Platform.Router msg msg ->
            msg ->
            State msg ->
            Task Never (State msg)
onSelfMsg =
  GenEffect.onSelfMsg
