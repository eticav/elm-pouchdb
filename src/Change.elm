effect module Change where { subscription = MySub } exposing ( ChangeOptions
                                                             , ChangeEvent(Changed,Completed,Error)
                                                             , Since(Now,Seq)
                                                             , new)

{- Change effects is a Pouchdb related modules. Its unique role is to provide a subscription mechanism to [Pouchdb](https://pouchdb.com/)[/CouchDB](http://couchdb.apache.org/) for your application. This library is to be used jointly with the Pouchdb.Db library.

# Definition
@docs now, ChangeOptions, ChangeEvent, Since


-}

import Native.Pouchdb exposing (..)
import Native.ElmPouchdbChange exposing (..)
  
import Task exposing (Task,map)
import Dict  exposing (Dict)
import Basics exposing (Never)
import Process exposing (spawn,kill)

import Json.Encode exposing (Value)
import Platform.Sub exposing (Sub)

import GenEffect exposing (..)
import Pouchdb exposing (Pouchdb,Doc)
import Native.ElmPouchdb exposing (changes)

{- Represents the events emited from the database.
-}

type ChangeEvent = Changed (Doc Value)
                 | Completed
                 | Error Value
                   
type alias SubEvent = GenEffect.SubEvent ChangeEvent
              
type alias SubId = String
                 
type alias NativeStart = GenEffect.NativeStart ChangeEvent

type alias Tagger msg = GenEffect.Tagger ChangeEvent msg

{- Represents a sequence related notion that specifies from when to start listening to the changes in the database. It is used within the ChangeOptions.
-}

type Since = Now
           | Seq Int

{- Represents all the options that can be used to listen to all events/changes occuring in the database.
-}

type alias ChangeOptions = { live: Bool
                           , include_docs: Bool
                           , include_conflicts: Bool
                           , attachments: Bool
                           , descending : Bool
                           , since: Since
                           , limit : Maybe Int }

{- Creates a new subscrition to the Pouchdb database.
-}

new : SubId->Pouchdb->ChangeOptions->(Tagger msg)->Sub msg
new id db opt tagger =
  subscription ( Change { id=id
                        , native=Native.ElmPouchdbChange.changes db opt
                        , tagger = tagger
                        }
               )

type alias ChangeType msg =  GenEffect.ChangeType ChangeEvent msg

type MySub msg = Change (ChangeType msg)

type alias Process msg = GenEffect.Process ChangeEvent msg
   
type alias Processes msg =
  Dict.Dict SubId (Process msg)

type alias State msg = { 
    processes : Processes msg
  }

subMap : (a -> b)
       -> MySub a
       -> MySub b
subMap f (Change mySub) =
  Change (GenEffect.subMap f mySub) 

init : Task Never (State msg)
init = GenEffect.init


onEffects : Platform.Router msg msg ->
            List (MySub msg) ->
            {b|processes:Processes msg}->
            Task Never (State msg)
onEffects router subs state =
  GenEffect.onEffects (\x-> case x of Change changeType -> changeType) router subs state
      
onSelfMsg : Platform.Router msg msg ->
            msg ->
            State msg ->
            Task Never (State msg)
onSelfMsg =
  GenEffect.onSelfMsg
