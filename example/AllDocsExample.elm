module AllDocsExample exposing (..)

{-| This module is an example of the Pouchdb allDocs task. It puts a couple of  documents in the database at init phase. Click the button to get alldocs from the database.

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
import Json.Decode as Json exposing (Decoder)

init : (Model, Cmd Message)
init =
  let
    model = initialModel
    tasks = [ (Pouchdb.put model.localDb (encoder "id3" "You got id3!") Nothing)
            , (Pouchdb.put model.localDb (encoder "id2" "You got id2!") Nothing)
            , (Pouchdb.put model.localDb (encoder "id1" "You got id1!") Nothing)
            ]
    cmd = Task.perform PutError PutSuccess (Task.sequence tasks)
  in 
    (model, cmd)

type alias DocModel = { id :String
                      , val : String }
    
type Message = PutButton
             | PutError Pouchdb.Fail
             | PutSuccess (List Pouchdb.Put)
             | AllDocsSuccess (Pouchdb.AllDocs Value)
             | AllDocsError Pouchdb.Fail
               
type alias Model = { localDb : Pouchdb
                   , docs : List DocModel
                   }

initialModel : Model
initialModel =
  let
    localDb = db "allDocs-Example" (dbOptions)
  in 
    { localDb = localDb
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
          ("val":=Decode.string)

update : Message -> Model -> (Model, Cmd Message)
update msg model =
  case msg of
    PutButton->
      let
        req= Pouchdb.allDocsRequest
             |> (Pouchdb.include_docs True)
             |> Pouchdb.startkey ["id2"]
             |> Pouchdb.endkey ["id3"]
             |> Pouchdb.inclusive_end False
                
        task = Pouchdb.allDocs model.localDb req
        cmd = Task.perform AllDocsError AllDocsSuccess task
      in
        (model,cmd)
    PutSuccess msg->
      (model, Cmd.none)
    PutError msg->
      (model, Cmd.none)
    AllDocsError msg->
      (model, Cmd.none)
    AllDocsSuccess msg->
      let
        filterMapFun aDoc =
          case aDoc.doc of
            Just val ->
              case Json.decodeValue decoder val of
                Ok doc-> Just doc
                Err _-> Nothing
            Nothing->Nothing
                     
        updatedDocs = List.filterMap filterMapFun msg.docs
      in 
      ({model|docs=updatedDocs}, Cmd.none)

      
view : Model -> Html Message
view model =
  div
    [ ]
    [ button [ onClick PutButton] [ text "All Docs now !!!"]
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
  Sub.none
           
main =  
  Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


