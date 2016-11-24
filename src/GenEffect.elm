module GenEffect exposing (..)

import Task exposing (Task,map)
import Dict  exposing (Dict)
import Basics exposing (Never)
import Process exposing (spawn,kill)

import Json.Encode exposing (Value)
import Platform.Sub exposing (Sub)

type alias SubEvent evt = evt
                        
type alias SubId = String
                 
type alias NativeStart evt = (SubEvent evt ->Task Never ()) -> Task Never ()


type alias Tagger evt msg = (SubEvent evt) -> msg


type alias Process evt msg = { tagger : (Tagger evt msg)
                             , pid : Platform.ProcessId
                             }
                       
type alias Processes evt msg =
  Dict.Dict SubId (Process evt msg)

type alias State evt msg = { 
    processes : Processes evt msg
  }

type alias ChangeType evt msg =  { id : SubId
                                 , native: NativeStart evt
                                 , tagger: Tagger evt msg
                                 }
         
subMap : (a -> b)
       -> ChangeType evt a
       -> ChangeType evt b
subMap f change = 
  {change | tagger = (f << change.tagger)}


onSelfMsg : Platform.Router msg msg ->
            msg ->
            State evt msg ->
            Task Never (State evt msg)
onSelfMsg router msg state =
  Platform.sendToApp router msg
            |> Task.andThen (\_ ->Task.succeed state)

call : NativeStart evt->
       (SubEvent evt ->Task Never ())->
       Task Never ()
call starter tagger =
  starter tagger            


init : Task Never (State evt msg)
init =
  Task.succeed (State Dict.empty)

  
onEffects : (x->ChangeType evt msg)->
            Platform.Router msg msg ->
            List x ->
            {b|processes:Processes evt msg}->
            Task Never (State evt msg)
onEffects convert router subs state =
  let
    allSubs = List.foldl (subToTagger convert) Dict.empty subs

    (inList,idemList, outList) = splitInOut allSubs state.processes
                                       
    inTasks = spawnInList router inList idemList
    outTasks = kill outList
  in
    outTasks |> Task.andThen (\_->Task.map State inTasks)

kill : List Platform.ProcessId ->  Task Never (List ())
kill outList =
  Task.sequence (List.map (\pid ->Process.kill pid) outList)
      
splitInOut : Dict SubId (ChangeType evt msg)->
             Processes evt msg->
           (List (ChangeType evt msg),Dict SubId (Process evt msg),List Platform.ProcessId)
splitInOut new old =
  let 
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
                                   new
                                   old
                                   ([], Dict.empty, [])
  in
    (inList,idemList, outList)
    
subToTagger : (x->ChangeType evt msg)->
              x->
              Dict.Dict SubId (ChangeType evt msg)->
              Dict.Dict SubId (ChangeType evt msg)
subToTagger convert mySub dict =
  let
    changeType = convert mySub
  in 
    Dict.insert changeType.id changeType dict

spawnInList : Platform.Router msg msg
      -> List (ChangeType evt msg)
      -> Processes evt msg
      -> Task.Task Never (Processes evt msg)

spawnInList router inList idemList=
  case inList of
    [] ->
      Task.succeed idemList
    head::rest ->
      Process.spawn (call head.native (sendToSelfChange router head.tagger))
               |> Task.andThen (\pid ->
                 spawnInList router rest (insertIntoProcesses head.id pid head.tagger idemList))

insertIntoProcesses : SubId -> Platform.ProcessId -> Tagger evt msg -> (Processes evt msg) -> (Processes evt msg)
insertIntoProcesses id pid tagger processes =
  let
    val = { pid=pid
          , tagger=tagger
          }
  in
    Dict.insert id val processes

sendToSelfChange : Platform.Router msg msg
                 -> (SubEvent evt-> msg)
                 -> SubEvent evt
                 -> Task Never ()
sendToSelfChange router tagger change =
  Platform.sendToSelf router (tagger change)
