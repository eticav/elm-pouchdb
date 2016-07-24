module PutExample exposing (..)

{-| This module is an example of the Pouchdb put task. It succeeds at first insertion, and fails on the second insertion which is normal because we are not using rev. As an exercise you could change the code to be able to do updates of the inserted document.
Have Fun!
-}
        
import Pouchdb exposing (Pouchdb,auth, ajaxCache,dbOptions,db,request)

import Html exposing (..)
import Html.App as Html
import String
import Html.Events exposing (onClick)
import Json.Encode as Encode exposing (object, Value)
import Task exposing (Task)

init : (Model, Cmd Message)
init =
  let
    model = initialModel
  in 
    (model, Cmd.none)
             
type Message = PutButton
             | PutError Pouchdb.Fail
             | PutSuccess Pouchdb.Put
               
type alias Model = { localDb : Pouchdb
                   , returnMsg : Maybe String
                   }

initialModel : Model
initialModel =
  let
    localDb = db "Put-Example" dbOptions
  in 
    { localDb = localDb
    , returnMsg = Nothing
    }

encoder : String->String->Encode.Value
encoder id val =
  Encode.object
          [ ("_id", Encode.string id)
          , ("val", Encode.string val)
          ]
  
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
  
view : Model -> Html Message
view model =
  div
    [ ]
    [ button [ onClick PutButton] [ text "Put"]
    , viewMsg model]

viewMsg model =
  case model.returnMsg of
    Just msg -> 
      div
        []
        [text msg]
    Nothing ->
      div
        []
        [text "No message yet!"]
                
subscriptions : Model -> Sub Message
subscriptions model =
  Sub.none
           
main =  
  Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


