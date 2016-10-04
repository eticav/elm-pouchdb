effect module Change where { subscription = MySub } exposing ( ChangeOptions
                                                             , changeOptions
                                                             , live
                                                             , since
                                                             , batch_size
                                                             , return_docs
                                                             , heartbeat
                                                             , timeout
                                                             , limit
                                                             , descending
                                                             , attachments
                                                             , include_conflicts
                                                             , include_docs
                                                             , filter
                                                             , ChangeEvent(..)
                                                             , Since(..)
                                                             , Filter(..)
                                                             , new
                                                             , SubId)

{-| Change effects is a Pouchdb related modules. Its unique role is to provide a subscription mechanism to [Pouchdb](https://pouchdb.com/)[/CouchDB](http://couchdb.apache.org/) for your application. This library is to be used jointly with the Pouchdb.Db library.

   -- example code take from example/ChangeExample.elm

    type Message = Change Change.ChangeEvent
                   | ...
    
    type alias DocModel = { id :String
                          , val : String }
        
    type alias Model = { localDb : Pouchdb
                       , docs : List DocModel
                       }
    ...                
    
    decoder : Decoder DocModel
    decoder = object2 DocModel
              ("_id":=Decode.string)
              ("val":=Decode.string)
                
    update : Message -> Model -> (Model, Cmd Message)
    update msg model =
      case msg of
        Change evt->
          case evt of
            Changed docValue ->
              let 
                decoded=case docValue.doc  of
                          Just val->case Decode.decodeValue decoder val of
                                      Ok doc-> Just doc
                                      Err _-> Nothing
                          Nothing->Nothing
                                   
                updatedDocs = case decoded of
                                Just doc -> doc::model.docs
                                Nothing -> model.docs
              in
                ({model|docs=updatedDocs},Cmd.none)
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
    
# Subscription definition
@docs new, ChangeOptions, changeOptions, Fail, ChangeEvent, Since, Filter, SubId

# Options Helpers functions
@docs live, since, batch_size, return_docs, heartbeat, timeout, limit, descending, attachments, include_conflicts, include_docs, filter


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


{-| Represents the events emited from the database.
-}
type ChangeEvent = Changed (Doc Value)
                 | Completed
                 | Error Fail

{-| Represents the error event emitted from the database.
-}                   
type alias Fail = { status: Int
                  , name: String
                  , message: String
                  }
                
type alias SubEvent = GenEffect.SubEvent ChangeEvent

                    
{-| Represents the subscription identifier
-}
type alias SubId = String
                 
type alias NativeStart = GenEffect.NativeStart ChangeEvent

type alias Tagger msg = GenEffect.Tagger ChangeEvent msg

                      
{-| Represents a sequence related notion that specifies from when to start listening to the changes in the database. It is used within the ChangeOptions.

    -- listening to changes from sequence number 500
    options = Change.changeOptions
                  |> since Seq 500
        
    change = Change.new "change1" model.localDb options Change

-}
type Since = Now
           | Seq Int

             
{-| Represents the filtering options used for replication.

    -- listening to changes from a view
    options = Change.changeOptions
                  |> filter (View "myview")


    --listening to changes from filter 
    options = Change.changeOptions
                  |> filter (Name "myfilter")


    --listening to changes from function that returns a boolean
    --only declare the body of the function where doc is the parameter
    options = Change.changeOptions
                  |> filter (Fun "{ return doc.type === 'marsupial'; }")

    --listening to changes within a list of docIds
    options = Change.changeOptions
                  |> filter (Ids ["id1","id2"])

-}                     
type Filter = View String
            | Name String
            | Fun String
            | Ids (List Pouchdb.DocId)
            | NoFilter

{-| Represents the query parameters.
-}              
type alias QueryParam = { key: String
                        , value: String
                        }


{-| Represents all the options that can be used to listen to all events/changes occuring in the database.
-}
type alias ChangeOptions = { live : Bool
                           , filter : Filter
                           --, query_params : List QueryParam TODO
                           , include_docs: Maybe Bool
                           , include_conflicts: Maybe Bool
                           , attachments: Maybe Bool
                           , descending : Maybe Bool
                           , since: Since
                           , limit : Maybe Int
                           , timeout : Maybe Int
                           , heartbeat : Maybe Int
                           , return_docs : Maybe Bool
                           , batch_size : Maybe Int}


{-| Use changeOptions to create the default [ChangeOptions](#ChangeOptions) and chain with helper setting functions.
-}
changeOptions : ChangeOptions
changeOptions = { live = True
                , filter = NoFilter
                --, query_params = [] TODO
                , include_docs= Just True
                , include_conflicts= Nothing
                , attachments= Nothing
                , descending = Nothing
                , since = Seq 0
                , limit = Nothing
                , timeout = Nothing
                , heartbeat = Nothing
                , return_docs = Nothing
                , batch_size = Nothing }

{-| Represents a helper function to set live. Can be chained to other helper functions.
-}
live : Bool->ChangeOptions->ChangeOptions
live val options =
  { options | live =  val}

{-| Represents a helper function to set filter. Can be chained to other helper functions.
-}
filter : Filter->ChangeOptions->ChangeOptions
filter val options =
  { options | filter =  val}

  
{- Represents a helper function to set query_params. Can be chained to other helper functions.

query_params : List QueryParam->ChangeOptions->ChangeOptions
query_params val options =
  { options | query_params =  val}
-}


{-| Represents a helper function to set include_docs. Can be chained to other helper functions.
-}
include_docs : Bool->ChangeOptions->ChangeOptions
include_docs val options =
  { options | include_docs = Just val}


{-| Represents a helper function to set include_conflicts. Can be chained to other helper functions.
-}
include_conflicts : Bool->ChangeOptions->ChangeOptions
include_conflicts val options =
  { options | include_conflicts = Just val}


{-| Represents a helper function to set attachments. Can be chained to other helper functions.
-}
attachments : Bool->ChangeOptions->ChangeOptions
attachments val options =
  { options | attachments = Just val}


{-| Represents a helper function to set descending. Can be chained to other helper functions.
-}
descending: Bool->ChangeOptions->ChangeOptions
descending val options =
  { options | descending = Just val}


{-| Represents a helper function to set since. Can be chained to other helper functions.
-}
since : Since->ChangeOptions->ChangeOptions
since val options =
  { options | since = val}


{-| Represents a helper function to set limit. Can be chained to other helper functions.
-}
limit : Int->ChangeOptions->ChangeOptions
limit val options =
  { options | limit = Just val}
    
{-| Represents a helper function to set timeout. Can be chained to other helper functions.
-}
timeout : Int->ChangeOptions->ChangeOptions
timeout val options =
  { options | timeout = Just val}


{-| Represents a helper function to set heartbeat. Can be chained to other helper functions.
-}
heartbeat : Int->ChangeOptions->ChangeOptions
heartbeat val options =
  { options | heartbeat = Just val}


{-| Represents a helper function to set return_docs. Can be chained to other helper functions.
-}
return_docs : Bool->ChangeOptions->ChangeOptions
return_docs val options =
  { options | return_docs = Just val}


{-| Represents a helper function to set batch_size. Can be chained to other helper functions.
-}
batch_size : Int->ChangeOptions->ChangeOptions
batch_size val options =
  { options | batch_size = Just val}

    
{-| Creates a new subscrition to the Pouchdb database.

    subscriptions : Model -> Sub Message
    subscriptions model =
      let
        options = Change.changeOptions
                  |> since Now
        
        change = Change.new "change1" model.localDb options Change
      in
      change
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
