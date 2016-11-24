module ElmPouchdb_Test exposing (..)


import Basics exposing (..)
import Test exposing (..)
import Pouchdb exposing (..)
import Change
import Replicate
import Sync
import Events
import Json.Encode as Encode exposing (object, string, Value)
import Json.Decode as Decode exposing (Decoder,field,string, map3)

import Html exposing (..)

import Date exposing (..)
import Task exposing (Task,perform)

import TestHelpers exposing (..)
        
init : (Model, Cmd Message)
init =
  let
    model = initialModel
    x = performNth Error Success model.taskIndex model.tasks
  in 
    (model, x)
             
type Message = Success Int TaskResult
             | Error Int TaskResult
             | Hello Date
             | Change Change.ChangeEvent
             | Replicate Replicate.ReplicateEvent
             

type DbStatus = Init
              | Created
              | Destroyed
            
type alias TestType = { id: String
                      , rev : String
                      , value : String         
                      }
            
type alias Model =
  {
    tasks : List TaskTest
  , taskIndex : Int
  , db : Pouchdb
  , remote : Pouchdb
  , date : Date
  , list : List Change.ChangeEvent
  }

decoder : Decoder TestType
decoder = map3 TestType
          (field "_id" Decode.string)
          (field "_rev" Decode.string)
          (field "val" Decode.string)

encoder : String->String->Encode.Value
encoder id val =
  Encode.object
          [ ("_id",Encode.string id)
          , ("val",Encode.string val)
          ]
                 
initTasks : Pouchdb -> Pouchdb ->List TaskTest
initTasks db remote=
  let
    list = [ taskTest
               "1"
               "Put simple doc"
               (OnSucceed (\x->x.id == "1518"))
               (Pouchdb.put db (encoder "1518" "hello") Nothing)
           , taskTest
               "2"
               "put another doc"
               (OnSucceed (\x->x.id == "2018"))
               (Pouchdb.put db (encoder "2018" "hello") Nothing)
           , taskTest
               "3"
               "put a doc with an already exisiting id without a rev"
               (OnFailure (\x->x.status == 409))
               (Pouchdb.put db (encoder "2018" "hello") Nothing)
           , taskTest
               "3"
               "put a doc with an already exisiting id without a wrong rev"
               (OnFailure (\x->x.status == 409 && x.name == "conflict"))
               (Pouchdb.put db (encoder "2018" "hello") (Just "1-1c276629cdf8502c81d3180fbb1b0126"))
           , taskTest
               "3"
               "Get simple exisiting doc without a rev"
               (OnSucceed (\x->x.id == "2018"))
               (Pouchdb.get db decoder
                  (Pouchdb.request "2018" Nothing |> revs True))
           -- , createAllDocsTaskTest
           --     "4"
           --     "Alls Docs"
           --     (Pouchdb.allDocsRequest
           --     |> startkey "1518"
           --     |> endkey "1818"
           --     |> include_docs True
           --     |> limit 1
           --     |> inclusive_end True) db
           -- , createQueryTaskTest
           --     "5"
           --     "Alls Docs : "
           --     (let req = Pouchdb.queryRequest (Map "{console.log(doc);emit([doc.val,1,'ddd']);};") in {req|include_docs=Just True}) db
           -- , taskTest
           --     "1000"
           --     "Delete database"
           --     (OnSucceed (\x->True))
           --     (Pouchdb.destroy db)
           -- , taskTest
           --     "1000"
           --     "Delete database"
           --     (OnSucceed (\x->True))
           --     (Pouchdb.destroy remote)
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
    { tasks = initTasks db remote
    , taskIndex = 1
    , db = db
    , remote = remote
    , date =Date.fromTime(0)
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
        updatedTask = updateTaskAt index something model.tasks
        newCmd = performNth Error Success  model.taskIndex model.tasks
        updatedTaskIndex =model.taskIndex + 1
      in
        ({model|tasks=updatedTask,taskIndex=updatedTaskIndex}, newCmd)
    Error index something ->
      let
        updatedTask = updateTaskAt index something model.tasks
        newCmd = performNth Error Success model.taskIndex  model.tasks
        updatedTaskIndex =model.taskIndex + 1
      in
        ({model|tasks=updatedTask,taskIndex=updatedTaskIndex}, newCmd)
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
    options = Change.changeOptions
            |> Change.since Change.Now
               
    change = Change.new "1" model.db options Change
             
    replicateOptions = Replicate.defaultOptions
                                    
                                    
    -- replication = Replicate.new "2" model.db model.remote
    --               {replicateOptions | since = Replicate.Seq 0}
    --                 Replicate
                                    
    sync = Sync.new "2" model.db model.remote
           replicateOptions
           replicateOptions
           Replicate
             
  in
    Debug.log("hello")
    Sub.batch [change, sync]
           
main =  
  Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
