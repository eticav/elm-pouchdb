module PutExample exposing (..)

{-| This module is an example of the Pouchdb put task. It succeeds at first insertion, and fails on the second insertion which is normal because we are not using rev. As an exercise you could change the code to be able to do updates of the inserted document.
Have Fun!
-}
        
import Pouchdb exposing (Pouchdb,auth, ajaxCache,dbOptions,db,request)

import Html exposing (..)

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
             | Put (Result Pouchdb.Fail Pouchdb.Put)
             
type alias Model = { localDb : Pouchdb
                   , returnMsg : Maybe String
                   }

initialModel : Model
initialModel =
  let
    localDb = db "Put-Example" dbOptions
  in 
    {
      localDb = localDb
    , returnMsg = Nothing
    }

encoder : String->String->Encode.Value
encoder id val =
  Encode.object
          [ ("_id", Encode.string id)
          , ("val", Encode.string val)
          ]

unpack : (e -> b) -> (a -> b) -> Result e a -> b
unpack errFunc okFunc result =
    case result of
        Ok ok ->
            okFunc ok
        Err err ->
            errFunc err
  
update : Message -> Model -> (Model, Cmd Message)
update msg model =
  case msg of
    PutButton->
      let 
        task = (Pouchdb.put model.localDb (encoder "id2" "hello") Nothing)
        cmd = Task.attempt Put task
      in
        (model, cmd)
    Put msg->
      let
        newMsg = unpack                 
                 (\m->String.append "Error putting in db with message = " m.message)
                 (\m->String.append "Successfully put in db with rev = " m.rev)
                  msg
       in
        ({model|returnMsg=Just newMsg}, Cmd.none)
  
view : Model -> Html Message
view model =
  div
    [ ]
    [ button [ onClick PutButton] [ text "Put"]
    , viewMsg model
    ]

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

main : Program Never Model Message
main =  
  Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


