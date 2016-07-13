module Main exposing (..)

import Basics exposing (..)
import ElmTest exposing (..)
import Pouchdb exposing (..)
import Change
import Replicate
import Sync
import Json.Encode as Encode exposing (object, string, Value)
import Json.Decode as Decode exposing (Decoder,(:=),string, object3)

import Html exposing (..)
import Html.App as Html
import Date exposing (..)
import Task exposing (Task,perform)

import TestHelpers exposing (..)
        
init : (Model, Cmd Message)
init =
  let
    model = initialModel
    x = performNth Error Success 1 model.tasks
  in 
    (model, x)
             
type Message = Success Int (DBSuccess TestType)
             | Error Int DBError
             | Hello Date
             | Change Change.ChangeEvent
             | Replicate Replicate.ReplicateEvent 

type alias TestType = { id: String
                      , rev : String
                      , value : String         
                      }
            
type alias Model =
  {
    tasks : List (TaskTest TestType)
  , db : Pouchdb
  , remote : Pouchdb
  , date : Date
  , fail : Maybe DBError
  , list : List Change.ChangeEvent
  }
                 
decoder : Decoder TestType
decoder = object3 TestType
          ("_id":=Decode.string)
          ("_rev":=Decode.string)
          ("val":=Decode.string)

encoder : String->String->Encode.Value
encoder id val =
  Encode.object
          [ ("_id",Encode.string id)
          , ("val",Encode.string val)
          ]
                 
initTasks : Pouchdb -> List (TaskTest TestType)
initTasks db =
  let
    list = [ createPutTaskTest
               "1"
               "Put simple doc"
               (encoder "1518" "hello")
               db
           , createPutTaskTest
               "2"
               "put simple doc"
               (encoder "2018" "hello")
               db
           , createGetTaskTest
               "3"
               "Get simple doc"
               decoder
               (Pouchdb.request "2018" Nothing |> revs True)
               db
           , createAllDocsTaskTest
               "4"
               "Alls Docs"
               (Pouchdb.allDocsRequest
               |> startkey "1518"
               |> endkey "1818"
               |> include_docs True
               |> limit 1
               |> inclusive_end True) db
           , createQueryTaskTest
               "5"
               "Alls Docs : "
               (let req = Pouchdb.queryRequest (Map "{console.log(doc);emit([doc.val,1,'ddd']);};") in {req|include_docs=Just True}) db
            -- createDestroyTaskTest
            --    "1000"
            --    "Delete database"
            --    db
           ]
  in
     list
          
initialModel : Model
initialModel =
  let
    db = Pouchdb.db "DB-Test" Pouchdb.dbOptions
    remote = Pouchdb.db "https://etiennecavard.cloudant.com/db-test"
             (Pouchdb.dbOptions
             |> auth "etiennecavard" "TGwF51P6K5TvXtg62mBt"
             |> ajaxCache True)
  in 
    { tasks = initTasks db 
    , db = db
    , remote = remote
    , date =Date.fromTime(0)
    , fail = Maybe.Nothing
    , list =[]}
  
update : Message -> Model -> (Model, Cmd Message)
update msg model =
  case msg of
    Hello date  ->
      let 
        updatedModel = {model | date = date}
      in
        (updatedModel, Cmd.none)
    Success index something ->
      let
        updatedTask = updateTaskAt index (TestHelpers.Ok something) model.tasks
        newCmd = performNth Error Success (index + 1) model.tasks
      in
        ({model|tasks=updatedTask}, newCmd)
    Error index something ->
      let
        updatedTask = updateTaskAt index (TestHelpers.Err something) model.tasks
        newCmd = performNth Error Success (index + 1) model.tasks
      in
        ({model|tasks=updatedTask}, newCmd)
    Change changeMsg ->
      let 
        updatedList = changeMsg::model.list
      in 
        ({model|list=updatedList}, Cmd.none)
      

    Replicate replicateMsg ->
        (model, Cmd.none)
  
view : Model -> Html Message
view model =
  div
    [ ]
    [ text "Testing PouchDB with elm"
    , text (toString (year model.date))
    , viewTasks model
    , viewChanges model]

viewTasks model =
  div
    []
    (List.map viewTask model.tasks)

viewTask task =
  div
    []
    [ span [][text (task.id)]
    , span [][text (task.description)]
    , span [][text (toString task.result)]]

viewChanges model =
  div
    []
    (List.map viewChange model.list)
  
viewChange change =
  div
    []
    [text (toString change)]
  
subscriptions : Model -> Sub Message
subscriptions model =
  let
    change = Change.new "1" model.db { live = True
                                     , include_docs = True
                                     , include_conflicts = True
                                     , attachments = False
                                     , descending  = False
                                     , since = Change.Now
                                     , limit  = Nothing } Change
             
    replicateOptions = Replicate.defaultOptions
                       
    -- replication = Replicate.new "2" model.db model.remote
    --               {replicateOptions | since = Replicate.Seq 0}
    --                 Replicate
    sync = Sync.new "2" model.db model.remote
           replicateOptions
           replicateOptions
           Replicate
     
  in
    Sub.batch [change, sync]
main =  
  Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
