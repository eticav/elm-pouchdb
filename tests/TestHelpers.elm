module TestHelpers exposing (..)

import Pouchdb exposing (..)
import Task exposing (Task,perform)
import Json.Encode exposing (object, string, Value)
import Json.Decode as Json exposing (Decoder)

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


type DBSuccess value = Put Pouchdb.Put
                     | Get (Pouchdb.Doc value)
                     | GetAllDocs (Pouchdb.AllDocs value)
                     | Query (Pouchdb.AllDocs value)
                     | Remove Pouchdb.Remove
                     | Destroy Pouchdb.SuccessDestroy
                 
type DBError = ErrPut Pouchdb.Fail
             | ErrGet Pouchdb.Fail
             | ErrGetAllDocs Pouchdb.Fail
             | ErrQuery Pouchdb.Fail
             | ErrRemove Pouchdb.Fail
             | ErrDestroy Pouchdb.FailDestroy

type alias TaskTest value = { id: String
                            , description : String
                            , task: Task.Task DBError (DBSuccess value)
                            , result : Maybe (TaskResult value)}

type TaskResult value = Ok (DBSuccess value)
                      | Err DBError

performNth : (Int->DBError->msg)->
             (Int->(DBSuccess value)->msg)->
             Int->
             List (TaskTest value)->
             Cmd msg
performNth errorTag successTag index tasks =
   case nth index tasks of
          Just t -> Task.perform (errorTag index) (successTag index) t.task
          Nothing -> Cmd.none

updateTaskAt : Int->TaskResult value->List (TaskTest value)->List (TaskTest value)
updateTaskAt index result tasks =
  updateAt index (\x->{x | result = Just result}) tasks

         
createPutTaskTest : String -> String -> Json.Encode.Value -> Pouchdb -> TaskTest value
createPutTaskTest id description object db =
  createPutUpdateTaskTest id description object Maybe.Nothing db 

createPutUpdateTaskTest : String -> String -> Json.Encode.Value -> Maybe String -> Pouchdb -> TaskTest value
createPutUpdateTaskTest id description object rev db =
  let
    task = (Pouchdb.put db object rev)
           |> Task.mapError ErrPut
           |> Task.map Put
  in
   TaskTest id description task Maybe.Nothing

   
createGetTaskTest : String -> String -> Json.Decoder value->DocRequest -> Pouchdb -> TaskTest value
createGetTaskTest id description decoder req db =
  let
    task = (Pouchdb.get db decoder req)
    task2 = Task.mapError ErrGet task
    task3 = Task.map Get task2
  in
   TaskTest id description task3 Maybe.Nothing

createAllDocsTaskTest : String -> String -> AllDocsRequest -> Pouchdb -> TaskTest value
createAllDocsTaskTest id description req db =
  let
    task = (Pouchdb.allDocs db req)
    task2 = Task.mapError ErrGetAllDocs task
    task3 = Task.map GetAllDocs task2
  in
   TaskTest id description task3 Maybe.Nothing

createQueryTaskTest : String -> String -> QueryRequest -> Pouchdb -> TaskTest value
createQueryTaskTest id description req db =
  let
    task = (Pouchdb.query db req)
    task2 = Task.mapError ErrQuery task
    task3 = Task.map Query task2
  in
   TaskTest id description task3 Maybe.Nothing
   
createDestroyTaskTest : String -> String -> Pouchdb -> TaskTest value
createDestroyTaskTest id description db =
  let
    task = (Pouchdb.destroy db)
    task2 = Task.mapError ErrDestroy task
    task3 = Task.map Destroy task2
  in
   TaskTest id description task3 Maybe.Nothing
