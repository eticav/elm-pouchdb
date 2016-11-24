module GetExample exposing (..)

{-| This module is an example of the Pouchdb get task. It puts a document in the databse at init phase. Click the button to get the doc from the database.

Have Fun!
-}
        
import Pouchdb exposing (Pouchdb,auth, ajaxCache,dbOptions,db,request)

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
    task = (Pouchdb.put model.localDb (encoder "id3" "You got me!") Nothing)
    cmd = Task.attempt Put task
  in 
    (model, cmd)

type alias DocModel = { id :String
                      , val : String }
    
type Message = GetButton
             | Put (Result Pouchdb.Fail Pouchdb.Put)
             | Get (Result Pouchdb.Fail (Pouchdb.Doc DocModel))             
               
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
decoder = map2 DocModel
          (field "_id" Decode.string)
          (field "val" Decode.string)

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
    GetButton->
      let
        req= Pouchdb.request "id3" Nothing
             |> Pouchdb.conflicts True
        -- Conflicts option not usefull here, but just a show case!
        task = Pouchdb.get model.localDb decoder req
        cmd = Task.attempt Get task
      in
        (model,cmd)
    Put msg->
      (model, Cmd.none)
    Get msg->
      let
        onFail m = (model, Cmd.none)
        onSuccess m = case m.doc of
                     Just doc ->
                       ({model|doc = Just doc}, Cmd.none)
                     Nothing ->
                       (model, Cmd.none)
      in
        unpack onFail onSuccess msg 
  
view : Model -> Html Message
view model =
  div
    [ ]
    [ button [ onClick GetButton] [ text "Get"]
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
