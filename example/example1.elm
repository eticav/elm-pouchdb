module Example1 exposing (..)
        
import Pouchdb exposing (Pouchdb,auth, ajaxCache,dbOptions,db,request)

import Html exposing (..)
import Html.App as Html
import String exposing (append)
import Html.Events exposing (onClick)
import Json.Encode as Encode exposing (object, string, Value)
import Json.Decode as Decode exposing (Decoder,(:=),string, object2)
import Task exposing (Task,perform)

init : (Model, Cmd Message)
init =
  let
    model = initialModel
  in 
    (model, Cmd.none)
             
type Message =
  PutButton
    | GetButton String
    | PutError String Pouchdb.Fail
    | PutSuccess String Pouchdb.Put
    | GetError String Pouchdb.Fail
    | GetSuccess String (Pouchdb.Doc DocModel)
    | NoOp

type alias DocModel = { id :String
                      , val : String }
    
type AppDoc = Id String
            | Doc DocModel
               
type alias Model =
  { index : Int
  , localDb : Pouchdb
  , remoteDb : Pouchdb
  , docs : List AppDoc
  }

                 
initialModel : Model
initialModel =
  let
    localDb = db "DB-Test" dbOptions
    remoteDb = db "https://etiennecavard.cloudant.com/db-test"
             (dbOptions
               |> auth "etiennecavard" "TGwF51P6K5TvXtg62mBt"
               |> ajaxCache True)
  in 
    { index=0
    , localDb = localDb
    , remoteDb = remoteDb
    , docs = []
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
          --("_rev":=Decode.string)
          ("val":=Decode.string)
  
update : Message -> Model -> (Model, Cmd Message)
update msg model =
  case msg of
    PutButton->
      let 
        newIndex=model.index+1
        id = (toString newIndex)
        task = (Pouchdb.put model.localDb (encoder id "hello") Nothing)
        cmd = Task.perform (PutError id) (PutSuccess id) task
      in
        ({model|index=newIndex},cmd)
    GetButton id->
      let
        req = request id Nothing
        task = (Pouchdb.get model.localDb decoder req)
        cmd = Task.perform (GetError id) (GetSuccess id) task
      in
        (model,cmd)
    PutSuccess id msg->
      let 
        updatedList = (Id id)::model.docs
      in
        ({model|docs=updatedList}, Cmd.none)
    GetSuccess id msg->
      let
        updatedList = case msg.doc of
                        Just doc->
                          List.map (\x-> case x of
                                           Id xId->if xId==doc.id then Doc doc else x
                                           _-> x)
                                   model.docs
                        Nothing->
                          model.docs
      in
        ({model|docs=updatedList}, Cmd.none)
    _ ->
      (model, Cmd.none)        
  
view : Model -> Html Message
view model =
  div
    [  ]
    [ button [ onClick PutButton] [ text (String.append "Put " (toString (model.index+1) ))]
    , viewDocs model]

viewDocs model =
  div
    []
    (List.map viewDoc model.docs)

viewDoc doc =
  case doc of
    Doc aDoc->
      div
        []
        [ span [][text (aDoc.val), text " from " ]
        
        , span [][text (aDoc.id)]]
    Id id ->
      div
        []
        [button [ onClick (GetButton id)] [ text (String.append "Get " id)]]
          
      
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


