effect module Events where { subscription = MySub }
       exposing ( ListenEvent( Created, Destroyed )
                , new)

{- Listens to database events 'created' and 'destroyed'. Listen effects is a Pouchdb related modules. Its unique role is to provide a subscription mechanism to [Pouchdb](https://pouchdb.com/)[/CouchDB](http://couchdb.apache.org/) for your application. This library is to be used jointly with the Pouchdb library.

# Definition
@docs new, ListenEvent, Since

-}

import Native.Pouchdb exposing (..)
import Native.ElmPouchdbEvents exposing (listen)
  
import Task exposing (Task,map)
import Dict  exposing (Dict)
import Basics exposing (Never)
import Process exposing (spawn,kill)

import Json.Encode exposing (Value)
import Platform.Sub exposing (Sub)

import GenEffect exposing (..)
--import Pouchdb exposing (Pouchdb)

{- Represents the events emited from the database which can be any of 'Destroyed', 'Created' events.
-}

type ListenEvent = Created String
                 | Destroyed String
                   
type alias SubEvent = GenEffect.SubEvent ListenEvent
              
type alias SubId = String
                 
type alias NativeStart = GenEffect.NativeStart ListenEvent

type alias Tagger msg = GenEffect.Tagger ListenEvent msg

             
{- Creates a new subscrition to the events of the Pouchdb database.
-}

new : SubId->(Tagger msg)->Sub msg
new id tagger =
  subscription ( Listen { id=id
                        , native=Native.ElmPouchdbEvents.listen
                        , tagger = tagger
                        }
               )

type alias ListenType msg =  GenEffect.ChangeType ListenEvent msg

type MySub msg = Listen (ListenType msg)

type alias Process msg = GenEffect.Process ListenEvent msg
   
type alias Processes msg =
  Dict.Dict SubId (Process msg)

type alias State msg = { 
    processes : Processes msg
  }

subMap : (a -> b)
       -> MySub a
       -> MySub b
subMap f (Listen mySub) =
  Listen (GenEffect.subMap f mySub) 

init : Task Never (State msg)
init = GenEffect.init


onEffects : Platform.Router msg msg ->
            List (MySub msg) ->
            {b|processes:Processes msg}->
            Task Never (State msg)
onEffects router subs state = GenEffect.onEffects (\x-> case x of Listen listenType -> listenType) router subs state
      
onSelfMsg : Platform.Router msg msg ->
            msg ->
            State msg ->
            Task Never (State msg)
onSelfMsg =
  GenEffect.onSelfMsg
