module Pouchdb exposing ( DocRequest
                        , AllDocsRequest
                        , QueryRequest
                        , JSFun(ViewName, Map, MapReduce)
                        , Pouchdb
                        , DocResult
                        , Fail
                        , FailDestroy
                        , SuccessPut
                        , db
                        , dbOptions
                        , auth
                        , ajaxCache
                        , queryRequest
                        , put
                        , get
                        , allDocs
                        , SuccessGetAllDocs
                        , query
                        , destroy
                        , SuccessDestroy
                        , request
                        , revs
                        , conflicts
                        , attachments
                        , binary
                        , allDocsRequest
                        )


{- This module provides an elm mapping to the great [pouchdb](https://pouchdb.com/) javascript library. Most of the functionalities have been mapped, it thefore provides a lot of functionalities among which: put, post, get, all docs, queries, listening to changes, syncing with other pouchdb or couchdb

-}

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
                 
{- Represents a doc request used by the function get.
-}

type alias DocRequest = { id: DocId
                        , rev: Maybe RevId
                        , revs: Maybe Bool
                        , conflicts : Maybe Bool
                        , attachments : Maybe Bool
                        , binary: Maybe Bool
                        }

{- A helper function for creating a default 'DocRequest'.
-}

request : DocId->Maybe RevId->DocRequest
request id rev = { id = id
                 , rev = rev
                 , revs = Maybe.Nothing
                 , conflicts = Maybe.Nothing
                 , attachments = Maybe.Nothing
                 , binary = Maybe.Nothing
                 }

revs : Bool->DocRequest->DocRequest
revs x request =
  {request|revs = Just x}

conflicts : Bool->{a|conflicts:Maybe Bool}->{a|conflicts:Maybe Bool}
conflicts x request =
  {request|conflicts = Just x}

attachments : Bool->{a|attachments:Maybe Bool}->{a|attachments:Maybe Bool}
attachments x request =
  {request|attachments = Just x}

binary : Bool->DocRequest->DocRequest
binary x request =
  {request|binary = Just x}
  
  
{- Represents a request used by the function all.
-}
                      
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

include_docs : Bool->{a|include_docs:Maybe Bool}->{a|include_docs:Maybe Bool}
include_docs x request =
  {request|include_docs = Just x}

startkey : DocId->
           {a|startkey:Maybe DocId,key:Maybe DocId, keys:Maybe (List DocId) }->
           {a|startkey:Maybe DocId,key:Maybe DocId, keys:Maybe (List DocId) }
startkey x request =
  {request|startkey = Just x, key=Nothing, keys=Nothing}

endkey : DocId->
           {a|endkey:Maybe DocId,key:Maybe DocId, keys:Maybe (List DocId) }->
           {a|endkey:Maybe DocId,key:Maybe DocId, keys:Maybe (List DocId) }
endkey x request =
  {request|endkey = Just x, key=Nothing, keys=Nothing}

inclusive_end : DocId->
           {a|inclusive_end:Maybe DocId,key:Maybe DocId, keys:Maybe (List DocId) }->
           {a|inclusive_end:Maybe DocId,key:Maybe DocId, keys:Maybe (List DocId) }
inclusive_end x request =
  {request|inclusive_end = Just x, key=Nothing, keys=Nothing}

limit : Int->{a|limit:Maybe Int}->{a|limit:Maybe Int}
limit x request =
  {request|limit = Just x}

skip : Int->{a|skip:Maybe Int}->{a|skip:Maybe Int}
skip x request =
  {request|skip = Just x}

descending : Int->{a|descending:Maybe Int}->{a|descending:Maybe Int}
descending x request =
  {request|descending = Just x}

key : DocId->
           {a|key:Maybe DocId, keys:Maybe (List DocId), startkey:Maybe DocId, endkey:Maybe DocId }->
           {a|key:Maybe DocId, keys:Maybe (List DocId), startkey:Maybe DocId, endkey:Maybe DocId }
key x request =
  {request|key = Just x, keys=Nothing, startkey=Nothing, endkey=Nothing}

keys : List DocId->
           {a|key:Maybe DocId, keys:Maybe (List DocId), startkey:Maybe DocId, endkey:Maybe DocId }->
           {a|key:Maybe DocId, keys:Maybe (List DocId), startkey:Maybe DocId, endkey:Maybe DocId }
keys x request =
  {request|keys = Just x, key=Nothing, startkey=Nothing, endkey=Nothing}
  

{- Represents a JS Map/Reduce function, a JS Map function or a view name. It is used within the QureyRequest object.
-}

type  JSFun = MapReduce String
            | Map String
            | ViewName String

{- Any of the standard reduce functions among which sum, count or stats, or a JS reduce function.
-}

type Reduce = Sum
            | Count
            | Stats
            | Fun Value

{- Represents a Stale Object.
-}
           
type Stale = Ok
           | UpdateAfter
            
{- Represents Query request object to be used in the query function.
-}
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
                        
{- A helper function for creating a default 'QueryRequest'.
-}
                        
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
                        
{- A helper function for creating a default 'AllDocsRequest'.
-}

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

-- TASKS OUTPUT --

{- When a function fails, this record will be received.
-}

type alias Fail = { status: Int
                  , name: String
                  , message: String
                  }
                
{- When a put or a post  succeeds , this record will be received.
-}

type alias SuccessPut = { id: DocId
                        , rev: RevId
                        }
{- Represents a revision.
-}
type alias Revision = { sequence : Int
                      , uuid  : RevId }
                    
{- The record received when the datavase is queried with get, all, or changes.
-}
                    
type alias DocResult = { id: DocId
                       , rev: Maybe RevId
                       , doc : Maybe Value
                       , revisions : Maybe (List Revision)
                       , conflicts : Maybe Value
                       , sequence : Maybe Int
                       , key : Maybe Value
                       }
{- When a 'all' or 'query' succeeds , this record will be received. Note, its a holder for a list of 'DocResult's.
-}

type alias SuccessGetAllDocs = { offset : Bool
                               , totalRows : Int
                               , docs : List DocResult
                               }
                             
{- Successful database deletion.
-}

type SuccessDestroy = Success
                    
{- Failure of a database deletion.
-}

type FailDestroy = Failed


type Adapter = Idb
             | LevelDb
             | WebSql
             | Http
             | Auto
       
type alias Options = { auto_compaction : Maybe Bool
                     , adapter : Adapter
                     , revs_limit : Maybe Int                     
                     , username : Maybe String
                     , password : Maybe String
                     , cache : Maybe Bool
                     , headers : Maybe Value
                     , withCredentials : Maybe Bool
                     , skip_setup : Maybe Bool
                     }

dbOptions : Options
dbOptions = { auto_compaction = Nothing
            , adapter = Auto
            , revs_limit = Nothing
            , username = Nothing
            , password = Nothing
            , cache = Nothing
            , headers = Nothing
            , withCredentials = Nothing
            , skip_setup = Nothing
            }

auth : String->String->Options->Options
auth username password options=
    { options | username=Just username, password=Just password}

ajaxCache : Bool->Options->Options
ajaxCache cache options =
  { options | cache=Just cache}
      
ajaxHeaders : Value->Options->Options
ajaxHeaders headers options =
  { options | headers=Just headers}
             
ajaxWithCredentials : Bool->Options->Options
ajaxWithCredentials withCredentials options =
  { options | withCredentials=Just withCredentials}

autoCompaction : Bool->Options->Options
autoCompaction autoCompaction options =
  {options | auto_compaction=Just autoCompaction}
  
revsLimit : Int->Options->Options
revsLimit limit options =
  {options | revs_limit=Just limit}

skipSetup : Bool->Options->Options
skipSetup skip options =
  { options | skip_setup=Just skip}

adapter : Adapter->Options->Options
adapter adapt options =
  { options | adapter=adapt}

{- Create a new database.
-}

db : a -> Options -> Pouchdb
db name options =
  Native.ElmPouchdb.db name options
        
{- Delete an existing database.
-}
        
destroy : Pouchdb-> Task FailDestroy SuccessDestroy
destroy db =
  Native.ElmPouchdb.destroy db

{- Put a document in the database.
-}
  
put : Pouchdb -> Value -> Maybe String-> Task Fail SuccessPut
put =
  Native.ElmPouchdb.put 

{- Post a document in the database.
-}
        
post : Pouchdb -> Value -> Task Fail SuccessPut
post =
  Native.ElmPouchdb.post 

{- Remove a document from the database.
-}
  
remove : Pouchdb -> DocId -> RevId-> Task Fail SuccessPut
remove db id rev=
  Native.ElmPouchdb.removeById db id (Just rev)

{- Retrieve a document from the database.
-}
  
get : Pouchdb -> DocRequest -> Task Fail DocResult
get db req =
  Native.ElmPouchdb.get db req

{- Fetch within all documenst in the databse.
-}
        
allDocs : Pouchdb -> AllDocsRequest -> Task Fail SuccessGetAllDocs
allDocs db req =
  Native.ElmPouchdb.allDocs db req

{- Query the database.
-}
  
query : Pouchdb -> QueryRequest -> Task Fail SuccessGetAllDocs
query db req =
  --Debug.log (toString req)
  Native.ElmPouchdb.query db req
