effect module Pouchdb where { subscription = MySub } exposing (..)

import Native.Pouchdb exposing (..)
import Native.ElmPouchdb exposing (..)
import Task exposing (Task,map)
import Basics exposing (Never)
import Process exposing (spawn,kill)

import Json.Encode exposing (Value)
import Platform.Sub exposing (Sub)
import Dict  exposing (Dict)

type Pouchdb = Pouchdb

-- TYPE DECLARATION

type alias DocId = String
type alias RevId = String
                 

type alias DocRequest = { id: DocId
                        , rev: Maybe RevId
                        , revs: Maybe Bool
                        , conflicts : Maybe Bool
                        , attachments : Maybe Bool
                        , binary: Maybe Bool
                        }

type alias AllDocsRequest = { include_docs : Maybe Bool
                            , conflicts : Maybe Bool
                            , attachments : Maybe  Bool
                            , startkey : Maybe DocId
                            , endkey : Maybe DocId
                            , inclusive_end : Maybe Bool
                            , limit : Maybe Int
                            , skip : Maybe Int
                            , descending : Maybe Bool
                            , key : Maybe DocId
                            , keys : Maybe (List DocId)
                            }


type  JSFun = MapReduce String
            | Map String
            | ViewName String

type Reduce = Sum
            | Count
            | Stats
            | Fun Value

type Stale = Ok
           | UpdateAfter
            
                          
type alias QueryRequest = { fun : JSFun
                          , reduce : Maybe Reduce
                          , include_docs : Maybe Bool
                          , conflicts : Maybe Bool
                          , attachments : Maybe  Bool
                          , startkey : Maybe DocId
                          , endkey : Maybe DocId
                          , inclusive_end : Maybe Bool
                          , limit : Maybe Int
                          , skip : Maybe Int
                          , descending : Maybe Bool
                          , groupLevel : Maybe Int               
                          , key : Maybe DocId
                          , keys : Maybe (List DocId)
                          , stale : Maybe Stale
                          }
                        
queryRequest : JSFun -> QueryRequest
queryRequest fun = { fun = fun
                   , reduce = Maybe.Nothing
                   , include_docs = Maybe.Nothing
                   , conflicts = Maybe.Nothing
                   , attachments = Maybe.Nothing
                   , startkey = Maybe.Nothing
                   , endkey = Maybe.Nothing
                   , inclusive_end = Maybe.Nothing
                   , limit = Maybe.Nothing
                   , skip = Maybe.Nothing
                   , descending = Maybe.Nothing
                   , groupLevel = Maybe.Nothing
                   , key = Maybe.Nothing
                   , keys = Maybe.Nothing
                   , stale = Maybe.Nothing
                   }
  
allDocsRequest :  AllDocsRequest
allDocsRequest = { include_docs = Maybe.Nothing
                 , conflicts = Maybe.Nothing
                 , attachments = Maybe.Nothing
                 , startkey = Maybe.Nothing
                 , endkey = Maybe.Nothing
                 , inclusive_end = Maybe.Nothing
                 , limit = Maybe.Nothing
                 , skip = Maybe.Nothing
                 , descending = Maybe.Nothing
                 , key = Maybe.Nothing
                 , keys = Maybe.Nothing
                 }

request : DocId -> DocRequest
request id = { id = id
             , rev = Maybe.Nothing
             , revs = Maybe.Nothing
             , conflicts = Maybe.Nothing
             , attachments = Maybe.Nothing
             , binary = Maybe.Nothing
             }

-- TASKS OUTPUT --                 

type alias Fail = { status: Int
                  , name: String
                  , message: String
                  }
                  
type alias SuccessPut = { id: DocId
                        , rev: RevId
                        }
type alias FailPut = Fail

type alias SuccessPost = { id: DocId
                         , rev: RevId
                         }
type alias FailPost = Fail

                      
type alias SuccessRemove = SuccessPut
type alias FailRemove = FailPut

type alias Revision = { sequence : Int
                      , uuid  : RevId }

type alias DocResult = { id: DocId
                       , rev: Maybe RevId
                       , doc : Maybe Value
                       , revisions : Maybe (List Revision)
                       , conflicts : Maybe Value
                       , sequence : Maybe Int
                       , key : Maybe Value
                       }

type alias FailGet = Fail
                   
type alias SuccessGetAllDocs = { offset : Bool
                               , totalRows : Int
                               , docs : List DocResult
                               }
      
type alias FailGetAllDocs = Fail


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
  
remove : Pouchdb -> DocId -> RevId-> Task FailRemove SuccessRemove
remove db id rev=
  Native.ElmPouchdb.removeById db id (Just rev)
  
get : Pouchdb -> DocRequest -> Task FailGet DocResult
get db req =
  Native.ElmPouchdb.get db req

allDocs : Pouchdb -> AllDocsRequest -> Task FailGetAllDocs SuccessGetAllDocs
allDocs db req =
  Native.ElmPouchdb.allDocs db req

query : Pouchdb -> QueryRequest -> Task FailGetAllDocs SuccessGetAllDocs
query db req =
  --Debug.log (toString req)
  Native.ElmPouchdb.query db req
-- EFFECT MANAGER

type ChangeEvent = Changed DocResult
                  | Completed
                  | Error Value

type alias SubId = String

type alias Tagger msg = ChangeEvent -> msg

type MySub msg =
  Change SubId Pouchdb ChangeOptions (Tagger msg)

change : SubId->Pouchdb->ChangeOptions->(Tagger msg)->Sub msg
change id db opt tagger=
       subscription ( Change id db opt tagger)
  
subMap :  (a -> b)
       -> MySub a
       -> MySub b
subMap f (Change id db opt tagger) =
  Change id db opt (f << tagger)

type Since = Now
           | Seq Int

type alias ChangeOptions = { live: Bool
                           , include_docs: Bool
                           , include_conflicts: Bool
                           , attachments: Bool
                           , descending : Bool
                           , since: Since
                           , limit : Maybe Int }
                           
--, timeout : Int  --TODO not impletemented for testing purpose
--, heartbeat: Int --TODO not impletemented for testing purpose
                           

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


onEffects : Platform.Router msg msg ->
             List (MySub msg) ->
             {b|processes:Processes msg}->
             Task Never (State msg)
onEffects router subs state =
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
                                   state.processes
                                   ([], Dict.empty, [])
                                       
    inTasks = spawnInList router inList idemList
    _=List.map (\x -> case x of
                        Just pid ->Process.kill pid
                        Nothing-> Task.succeed ()) outList
  in
    Task.map State inTasks
          
subToTagger : MySub msg-> Dict.Dict SubId (MySub msg) -> Dict.Dict SubId (MySub msg)
subToTagger (Change id db opt tagger) dict =
  Dict.insert id (Change id db opt tagger) dict


spawnInList : Platform.Router msg msg ->
              List (MySub msg) ->
              Processes msg->
              Task Never (Processes msg)
spawnInList router inList idemList =
  case inList of
    [] ->
      Task.succeed idemList

    (Change id db opt tagger)::rest ->
      Process.spawn (setChange (Change id db opt tagger)
                                (sendToSelfChange router tagger)
                                (sendToSelfChange router tagger)
                                (sendToSelfChange router tagger ))
              `Task.andThen` \pid ->
                spawnInList router rest (insertIntoProcesses id pid tagger idemList)

insertIntoProcesses : SubId -> Platform.ProcessId -> Tagger msg -> (Processes msg) -> (Processes msg)
insertIntoProcesses id pid tagger processes =
  let
    val = { pid=Just pid,
            tagger=tagger}
  in 
    Dict.insert id val processes
      
onSelfMsg : Platform.Router msg msg ->
            msg ->
            State msg ->
            Task Never (State msg)
onSelfMsg router msg state =
  Platform.sendToApp router msg
            `Task.andThen` \_ ->Task.succeed state

setChange : MySub msg->
            (ChangeEvent->Task Never ()) ->
            (ChangeEvent->Task Never ()) ->
            (ChangeEvent->Task Never ()) ->
            Task x Never
setChange  (Change id db opt tagger)
           toChangeTask
           toCompleteTask
           toErrorTask =
  Native.ElmPouchdb.changes db opt
        toChangeTask
        toCompleteTask
        toErrorTask

sendToSelfChange : Platform.Router msg msg
                 -> (ChangeEvent -> msg)
                 -> ChangeEvent
                 -> Task Never ()
sendToSelfChange router tagger change =
  Platform.sendToSelf router (tagger change)
