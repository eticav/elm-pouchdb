module ReplicateExample exposing (..)

{-| This module is an example of the Pouchdb replication subscription. Click on the button to post a new document. The documents are inserted in sourceDb and replicated to destDb. Changes are listened on destDb in order to display newly replictaed events...
Have Fun!
-}
        
import Pouchdb exposing (Pouchdb,auth, ajaxCache,dbOptions,db)
import Change exposing (..)
import Replicate exposing (..)

import Html exposing (..)

import String
import Html.Events exposing (onClick)
import Json.Encode as Encode exposing (object, Value)
import Json.Decode as Decode exposing (Decoder,field,string, map2)
import Task exposing (Task)

init : (Model, Cmd Message)
init =
  let
    model = initialModel
  in 
    (model, Cmd.none)
             
type Message = PutButton
             | Put (Result Pouchdb.Fail Pouchdb.Put)
             | Change Change.ChangeEvent
             | Replicate Replicate.ReplicateEvent
             | NoOp

type alias DocModel = { id :String
                      , val : String }
    
type alias Model = { sourceDb : Pouchdb
                   , destDb : Pouchdb
                   , docs : List DocModel
                   }
                 
initialModel : Model
initialModel =
  let
    sourceDb = db "Replicate-Example-source" (dbOptions)
    destDb = db "Replicate-Example-dest" (dbOptions)
  in 
    { sourceDb = sourceDb
    , destDb = destDb
    , docs = []
    }
    
encoder : String->Encode.Value
encoder val =
  Encode.object
          [  ("val", Encode.string val)
          ]

decoder : Decoder DocModel
decoder = map2 DocModel
          (field "_id" Decode.string)
          (field "val" Decode.string)
            
update : Message -> Model -> (Model, Cmd Message)
update msg model =
  case msg of
    PutButton->
      let 
        task = (Pouchdb.post model.sourceDb (encoder "Bonjour Monde!"))
        cmd = Task.attempt Put task
      in
        (model,cmd)
    Put msg->
      (model,Cmd.none)
    Change evt->
      case evt of
        Change.Changed docValue ->
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
        Change.Completed->(model,Cmd.none)
        Change.Error _ ->(model,Cmd.none)
    Replicate evt->
      -- providing all cases here, for documentation only
      case evt of
        Replicate.Completed value->(model,Cmd.none)
        Replicate.Active value->(model,Cmd.none)
        Replicate.Paused value->(model,Cmd.none)
        Replicate.Changed value->(model,Cmd.none)
        Replicate.Denied value->(model,Cmd.none)
        Replicate.Error value->(model,Cmd.none)
    NoOp ->
      (model,Cmd.none)
      
  
view : Model -> Html Message
view model =
  div
    [ ]
    [ button [ onClick PutButton] [ text "Post new doc !!"]
    , viewDocs model.docs]

viewDocs docs =
  div
    [ ]
    (List.map viewDoc docs)

viewDoc doc =
  div
    [ ]
    [ text doc.val ]
                
subscriptions : Model -> Sub Message
subscriptions model =
  let
    options = Change.changeOptions
              |> Change.since Change.Now
    
    change = Change.new "change1" model.destDb options Change

    replOpt = Replicate.defaultOptions
    
    replication = Replicate.new "replication" model.sourceDb model.destDb replOpt Replicate
  in
  Sub.batch [change, replication]
           
main =  
  Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


