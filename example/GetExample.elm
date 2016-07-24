module GetExample exposing (..)

{-| This module is an example of the Pouchdb get task. It puts a document in the databse at init phase. Click the button to get the doc from the database.

Have Fun!
-}
        
import Pouchdb exposing (Pouchdb,auth, ajaxCache,dbOptions,db,request)

import Html exposing (..)
import Html.App as Html
import String
import Html.Events exposing (onClick)
import Json.Encode as Encode exposing (object, Value)
import Json.Decode as Decode exposing (Decoder,(:=),string, object2)
import Task exposing (Task)

init : (Model, Cmd Message)
init =
  let
    model = initialModel
    task = (Pouchdb.put model.localDb (encoder "id3" "You got me!") Nothing)
    cmd = Task.perform PutError PutSuccess task
  in 
    (model, cmd)

type alias DocModel = { id :String
                      , val : String }
    
type Message = PutButton
             | PutError Pouchdb.Fail
             | PutSuccess Pouchdb.Put
             | GetSuccess (Pouchdb.Doc DocModel)
             | GetError Pouchdb.Fail
               
type alias Model = { localDb : Pouchdb
                   , doc : Maybe DocModel
                   }

initialModel : Model
initialModel =
  let
    localDb = db "Get-Example" (dbOptions)
  in 
    { localDb = localDb
    , doc = Nothing
    }

encoder : String->String->Encode.Value
encoder id val =
  Encode.object
          [ ("_id", Encode.string id)
          , ("val", Encode.string val)
          ]
decoder : Decoder DocModel
decoder = object2 DocModel
          ("_id":=Decode.string)
          ("val":=Decode.string)

update : Message -> Model -> (Model, Cmd Message)
update msg model =
  case msg of
    PutButton->
      let
        req= Pouchdb.request "id3" Nothing
             |> Pouchdb.conflicts True
        -- Conflicts option not usefull here, but just a show case!
        task = Pouchdb.get model.localDb decoder req
        cmd = Task.perform GetError GetSuccess task
      in
        (model,cmd)
    PutSuccess msg->
      (model, Cmd.none)
    PutError msg->
      (model, Cmd.none)
    GetSuccess msg->
      case msg.doc of
        Just doc ->
          ({model|doc = Just doc}, Cmd.none)
        Nothing ->
          (model, Cmd.none)
    GetError msg->
      -- handle fail here
      (model, Cmd.none)
  
view : Model -> Html Message
view model =
  div
    [ ]
    [ button [ onClick PutButton] [ text "Put"]
    , viewMsg model]

viewMsg model =
  case model.doc of
    Just doc -> 
      div
        []
        [text doc.val]
    Nothing ->
      div
        []
        [text "No doc yet! Please push the button..."]
                
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


