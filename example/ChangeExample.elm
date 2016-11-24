module ChangeExample exposing (..)

{-| This module is an example of the Pouchdb change subscription. Click on the button to post a new document. All chnage events since 'now' will be displayed... As an exercise try displaying all docs from the database.
Have Fun!
-}
        
import Pouchdb exposing (Pouchdb,auth, ajaxCache,dbOptions,db)
import Change exposing (..)

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

type alias DocModel = { id :String
                      , val : String }
    
type alias Model = { localDb : Pouchdb
                   , docs : List DocModel
                   }
                 
initialModel : Model
initialModel =
  let
    localDb = db "Change-Example" (dbOptions)
  in 
    { localDb = localDb
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
        task = (Pouchdb.post model.localDb (encoder "Bonjour Monde!"))
        cmd = Task.attempt Put task
      in
        (model,cmd)
    Put msg->
      (model,Cmd.none)
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
        Completed->(model,Cmd.none)
        Error _ ->(model,Cmd.none)
      
  
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
              |> since Now
    
    change = Change.new "change1" model.localDb options Change
  in
  change
           
main =  
  Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


