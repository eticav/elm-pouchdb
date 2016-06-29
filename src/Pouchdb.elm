effect module Pouchdb where { subscription = MySub } exposing (..)

import Native.Pouchdb exposing (..)
import Native.ElmPouchdb exposing (..)
import Task exposing (Task,map)
import Basics exposing (Never)

import Json.Encode exposing (Value)
import Platform.Sub exposing (Sub)
import Dict  exposing (Dict)

type Pouchdb = Pouchdb

-- TYPE DECLARATION

type alias DocRequest = { id: String
                        , rev: Maybe String
                        , revs: Maybe Bool
                        , attachments : Maybe Bool
                        , binary: Maybe Bool
                        }

request : String -> DocRequest
request id = { id = id
             , rev = Maybe.Nothing
             , revs = Maybe.Nothing
             , attachments = Maybe.Nothing
             , binary = Maybe.Nothing
             }

-- TASKS OUTPUT --                 

type alias Fail = { status: Int
                  , name: String
                  , message: String
                  }
                  
type alias SuccessPut = { id: String
                        , rev: String
                        }
type alias FailPut = Fail

type alias SuccessPost = { id: String
                         , rev: String
                         }
type alias FailPost = Fail

                      
type alias SuccessRemove = SuccessPut
type alias FailRemove = FailPut

type alias Revision = { sequence : Int
                      , uuid  : String }

type alias SuccessGet = { response : Value
                        , conflicts : Maybe Value
                        , revisions : Maybe (List Revision)
                        }

type alias FailGet = Fail

type SuccessDestroy = Success
type FailDestroy = Failed


db : a -> Pouchdb
db=
  Native.ElmPouchdb.db

destroy : Pouchdb-> Task FailDestroy SuccessDestroy
destroy db =
  Native.ElmPouchdb.destroy db
  
put : Pouchdb -> Value -> Maybe String-> Task FailPut SuccessPut
put =
  Native.ElmPouchdb.put 

post : Pouchdb -> Value -> Task FailPost SuccessPost
post =
  Native.ElmPouchdb.post 
  
remove : Pouchdb -> String -> Maybe String-> Task FailRemove SuccessRemove
remove db id rev=
  Native.ElmPouchdb.removeById db id rev
  
get : Pouchdb -> DocRequest -> Task FailGet SuccessGet
get db req =
  Native.ElmPouchdb.get db req


-- EFFECT MANAGER

type ChangeEvent = Changed Value
                  | Completed Value
                  | Error Value

type alias SubId = String

type alias Tagger msg = ChangeEvent -> msg

type MySub msg =
  Change SubId Pouchdb ChangeOptions (Tagger msg)

subMap :  (a -> b)
       -> MySub a
       -> MySub b
subMap f (Change id db opt tagger) =
  Change id db opt (f << tagger)

type Since = Now
           | Seq Int
         
type alias ChangeOptions = { since: Since
                           , live: Bool
                           , include_docs: Bool
                           }

-- EFFECT MANAGER

type alias Process msg = { tagger : (Tagger msg)
                         , pid : Maybe Platform.ProcessId}
                   
type alias Processes msg =
  Dict.Dict SubId (Process msg)

type alias State msg = { 
    processes : Processes msg
  }

init : Task Never (State msg)
init =
  Task.succeed (State Dict.empty)


onEffects : Platform.Router msg ChangeEvent ->
            List (MySub msg) ->
            State msg ->
            Task Never (State msg)
onEffects router subs {processes} =
  let
    allSubs = List.foldl subToTagger Dict.empty subs
    inFun _ sub (inList, idemList, outList) =
      (sub::inList, idemList, outList)
    idemFun id  _ x (inList,idemList,outList) =
      (inList, Dict.insert id x idemList, outList)
    outFun _ {pid} (inList,idemList,outList) =
      (inList,idemList, pid::outList)
    (inList,idemList, outList) = Dict.merge
                                   inFun
                                   idemFun
                                   outFun
                                   allSubs
                                   processes
                                   ([], Dict.empty, [])
                                       
    inTasks = spawnInList router inList idemList
    _=List.map (\x -> Native.Scheduler.kill x) outList
  in
    Task.map State inTasks
          
subToTagger : MySub msg-> Dict.Dict SubId (MySub msg) -> Dict.Dict SubId (MySub msg)
subToTagger (Change id db opt tagger) dict =
  Dict.insert id (Change id db opt tagger) dict


spawnInList : Platform.Router msg ChangeEvent ->
              List (MySub msg) ->
              Processes msg->
              Task Never (Processes msg)
spawnInList router inList idemList =
  case inList of
    [] ->
      Task.succeed idemList

    (Change id db opt tagger)::rest ->
      Native.Scheduler.spawn (setChange (Change id db opt tagger)
                                (sendToSelfChange router  (Changed >> tagger) )
                                (sendToSelfChange router  (Completed >> tagger) )
                                (sendToSelfChange router  (Error >> tagger) ))
              `Task.andThen` \pid ->
                spawnInList router rest (insertIntoProcesses id pid tagger idemList)

insertIntoProcesses : SubId -> Platform.ProcessId -> Tagger msg -> (Processes msg) -> (Processes msg)
insertIntoProcesses id pid tagger processes =
  let
    val = { pid=Just pid,
            tagger=tagger}
  in 
    Dict.insert id val processes
      
onSelfMsg : Platform.Router msg ChangeEvent ->
            msg ->
            State msg ->
            Task Never (State msg)
onSelfMsg router event state =
  Platform.sendToApp router event
            `Task.andThen` \_ ->Task.succeed state

setChange : MySub msg->
            (Value->Task Never ()) ->
            (Value->Task Never ()) ->
            (Value->Task Never ()) ->
            Task x Never
setChange  (Change id db opt tagger)
           toChangeTask
           toCompleteTask
           toErrorTask =
  Native.ElmPouchdb.change db opt
        toChangeTask
        toCompleteTask
        toErrorTask 

--sendToSelfChange : Platform.Router msg ChangeEvent ->
  --                 (ChangeEvent -> msg)->
    --               (Value->ChangeEvent)->
      --             Value->
        --           Task c ()
sendToSelfChange router ctor change =
  Platform.sendToSelf router ctor
