module TestHelpers exposing (..)

import Pouchdb exposing (..)
import Task exposing (Task,perform)
import Json.Encode exposing (object, string, Value)
import Json.Decode as Json exposing (Decoder)
import Regex

updateAt : Int-> (a -> a) -> List a -> List a
updateAt index fun list =
  case index > 0 of
    True->
      let
        h = List.take (index-1) list
        t = List.drop (index-1) list
        t2 = List.drop 1 t
        element = case (List.head t) of
                    Just e -> [fun e]
                    _ -> []
      in
        List.append h (List.append element t2)
    _-> list

nth : Int -> List a -> Maybe a
nth index list =
  case index > 0 of
    True->
      let
        t = List.drop (index-1) list
      in
        List.head t
    _-> Nothing

type alias TaskTest = { id: String
                      , description : String
                      , task: Task.Task TaskResult TaskResult
                      , result : Maybe TaskResult}

type AssertType error success = OnSucceed (success->Bool)
                              | OnFailure (error->Bool)

type TaskResult = Succeed String
                | Fail String

contains : String -> TaskResult -> Bool
contains str taskResult =
  let 
    string = case taskResult of
               Succeed r -> r
               Fail r -> r
  in
    Regex.contains (Regex.regex str) string
      
performNth : (Int->TaskResult->msg)->
             (Int->TaskResult->msg)->
             Int->
             List TaskTest->
             Cmd msg
performNth errorTag successTag index tasks =
   case nth index tasks of
          Just t -> Task.perform (errorTag index) (successTag index) t.task
          Nothing -> Cmd.none

updateTaskAt : Int->TaskResult->List TaskTest->List TaskTest
updateTaskAt index result tasks =
  updateAt index (\x->{x | result = Just result}) tasks

taskTest : String -> String -> AssertType a b-> Platform.Task a b->TaskTest
taskTest id description assertion fun =
  let
    task = case assertion of
             OnFailure ass -> 
               fun
                 |> Task.mapError (\x-> if ass x
                                        then Succeed (toString x)
                                        else Fail (toString x)) 
                 |> Task.map (\x -> Fail (toString x))
             OnSucceed ass ->
               fun
                 |> Task.mapError (\x -> Fail (toString x))
                 |> Task.map (\x-> if ass x
                                   then Succeed (toString x)
                                   else Fail (toString x)) 
  in
    TaskTest id description task Maybe.Nothing
