module Pouchdb exposing ( JSFun(ViewName, Map, MapReduce)
                        , Doc
                        , Fail
                        , FailDestroy
                        , Put
                        , Post
                        , Remove
                        , AllDocs
                        , SuccessDestroy
                        , Pouchdb
                        , db
                        , Options
                        , dbOptions
                        , destroy
                        , put
                        , post
                        , remove
                        , getValue
                        , get
                        , fromValue
                        , DocRequest
                        , request
                        , allDocs
                        , AllDocsRequest
                        , allDocsRequest
                        , query
                        , QueryRequest
                        , queryRequest
                        -- database helpers
                        , auth
                        , ajaxCache
                        , adapter
                        , skipSetup
                        , revsLimit
                        , autoCompaction
                        , ajaxWithCredentials
                        , ajaxHeaders
                        -- helpers
                        , revs
                        , conflicts
                        , attachments
                        , binary
                        , keys
                        , key
                        , descending
                        , skip
                        , limit
                        , inclusive_end
                        , endkey
                        , startkey
                        , include_docs
                        )

{- This module provides an elm mapping to the great [pouchdb](https://pouchdb.com/) javascript library. Most of the functionalities have been mapped, it therefore provides a lot of functionalities among which: put, post, get, all docs, queries, listening to changes, syncing with other pouchdb or couchdb

# Database operations
@docs db, Options, destroy, dbOptions

## Database helper functions
@docs auth, ajaxCache, adapter, skipSetup, revsLimit, autoCompaction, ajaxWithCredentials, ajaxHeaders


# Document operations
@docs put, post, remove, get, allDocs, query

# Requests helper functions
@docs revs, conflicts, attachments, binary, keys, key, descending, skip, limit, inclusive_end, endkey, startkey, include_docs
-}

import Native.Pouchdb exposing (..)
import Native.ElmPouchdb exposing (..)
import Task exposing (Task,map,andThen,succeed,fail)
import Basics exposing (Never)
import Process exposing (spawn,kill)

import Json.Encode exposing (Value)
import Json.Decode as Json exposing (Decoder)
import Platform.Sub exposing (Sub)
import Dict  exposing (Dict)

type Pouchdb = Pouchdb

type alias DocId = String
type alias RevId = String
                 
{- Represents a doc request used by the 'get' function. You should use the 'request' function for minimal setup.
-}
type alias DocRequest = { id: DocId
                        , rev: Maybe RevId
                        , revs: Maybe Bool
                        , conflicts : Maybe Bool
                        , attachments : Maybe Bool
                        , binary: Maybe Bool
                        }

                     
{- A helper function for creating a minimum 'DocRequest'. The helper functions 'revs', 'conflicts', 'attachments' and 'binary' are provided to complete the doc request. Use them instead of accessing directly to the record.
-}
request : DocId->Maybe RevId->DocRequest
request id rev = { id = id
                 , rev = rev
                 , revs = Maybe.Nothing
                 , conflicts = Maybe.Nothing
                 , attachments = Maybe.Nothing
                 , binary = Maybe.Nothing
                 }


{- Represents a helper function for including revision history of the document.
-}
revs : Bool->DocRequest->DocRequest
revs x request =
  {request|revs = Just x}

    
{- Represents a helper function to use when doing requests. If used, conflicting leaf revisions will be attached in a conflicts list.
-}
conflicts : Bool->{a|conflicts:Maybe Bool}->{a|conflicts:Maybe Bool}
conflicts x request =
  {request|conflicts = Just x}

    
{- Represents a helper function to use when doing requests. If used, attachement data will be retreived.
-}  
attachments : Bool->{a|attachments:Maybe Bool}->{a|attachments:Maybe Bool}
attachments x request =
  {request|attachments = Just x}

    
{- Represents a helper function to use when doing requests. If used jointle with attachments, it returns data as Blob/Buffers. Not tested! Use at your own risk.
-}    
binary : Bool->DocRequest->DocRequest
binary x request =
  {request|binary = Just x}
  
  
{- Represents a request used by the function 'all'. You should use the 'allDocsRequest' function for minimal setup.
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

                          
{- A helper function for creating a miniumum 'AllDocsRequest'. The helper functions 'include_docs', 'conflicts', 'attachments', 'startkey', 'endkey', 'inclusive_end', 'limit', 'skip', 'descending', 'key' and 'keys'  are provided to complete the query request. Use them instead of accessing directly to the record.
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


{- Represents a helper function to use when doing requests. If used, include the document itself.
-}
include_docs : Bool->{a|include_docs:Maybe Bool}->{a|include_docs:Maybe Bool}
include_docs x request =
  {request|include_docs = Just x}
    
    
{- Represents a helper function to use when doing requests. If used, get documents with IDs in a certain range starting at 'startkey'.
-}
startkey : DocId->
           {a|startkey:Maybe DocId,key:Maybe DocId, keys:Maybe (List DocId) }->
           {a|startkey:Maybe DocId,key:Maybe DocId, keys:Maybe (List DocId) }
startkey x request =
  {request|startkey = Just x, key=Nothing, keys=Nothing}
    

{- Represents a helper function to use when doing requests. If used, get documents with IDs in a certain range ending at 'endkey'.
-}
endkey : DocId->
           {a|endkey:Maybe DocId,key:Maybe DocId, keys:Maybe (List DocId) }->
           {a|endkey:Maybe DocId,key:Maybe DocId, keys:Maybe (List DocId) }
endkey x request =
  {request|endkey = Just x, key=Nothing, keys=Nothing}

    
{- Represents a helper function to use when doing requests. If used, includes the 'endkey' document.
-}
inclusive_end : Bool->
           {a|inclusive_end:Maybe Bool,key:Maybe DocId, keys:Maybe (List DocId) }->
           {a|inclusive_end:Maybe Bool,key:Maybe DocId, keys:Maybe (List DocId) }
inclusive_end x request =
  {request|inclusive_end = Just x, key=Nothing, keys=Nothing}
    

{- Represents a helper function to use when doing requests. If used, sets the maximum number of documents to return.
-}
limit : Int->{a|limit:Maybe Int}->{a|limit:Maybe Int}
limit x request =
  {request|limit = Just x}
    
    
{- Represents a helper function to use when doing requests. If used, sets the number of docs to skip before returning. Pouchdb documentation indicates poor performance, use 'startkey'/'endkey' instead.
-}
skip : Int->{a|skip:Maybe Int}->{a|skip:Maybe Int}
skip x request =
  {request|skip = Just x}
    

{- Represents a helper function to use when doing requests. If used, reverses the order of the output documents.
-}
descending : Bool->{a|descending:Maybe Bool}->{a|descending:Maybe Bool}
descending x request =
  {request|descending = Just x}
    

{- Represents a helper function to use when doing requests. If used, the request only retruns the document with the matching key.
-}
key : DocId->
           {a|key:Maybe DocId, keys:Maybe (List DocId), startkey:Maybe DocId, endkey:Maybe DocId }->
           {a|key:Maybe DocId, keys:Maybe (List DocId), startkey:Maybe DocId, endkey:Maybe DocId }
key x request =
  {request|key = Just x, keys=Nothing, startkey=Nothing, endkey=Nothing}
    
    
{- Represents a helper function to use when doing requests. If used, the request only retruns the documents with the list of keys.
-}
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
             
            
{- Represents Query request object to be used in the query function. You should use the 'queryRequest' function for minimal setup.
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
                        
                        
{- A helper function for creating a default 'QueryRequest'. The helper functions 'reduce','conflicts','attachments','startkey','endkey','inclusive_end','limit','skip','descending','groupLevel','key','keys','stale' are provided to complete the query request. Use them instead of accessing directly to the record.
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
                  

{- When a function fails, this record will be received.
-}
type alias Fail = { status: Int
                  , name: String
                  , message: String
                  }
                
                
{- When a put  succeeds , this record will be received.
-}
type alias Put = { id: DocId
                 , rev: RevId
                 }

               
{- When a post  succeeds , this record will be received.
-}
type alias Post = Put

                
{- When a remove  succeeds , this record will be received.
-}
type alias Remove = Put
                      
                      
{- Represents a revision.
-}
type alias Revision = { sequence : Int
                      , uuid  : RevId }
                    
                    
{- The record received when the datavase is queried with 'get', 'all', or 'changes' functions.
-}
type alias Doc value = { id: DocId
                       , rev: Maybe RevId
                       , doc : Maybe value
                       , revisions : Maybe (List Revision)
                       , conflicts : Maybe Value
                       , sequence : Maybe Int
                       , key : Maybe Value
                       }


{- When a 'all' or 'query' succeeds , this record will be received. Note, its a holder for a list of 'Doc's.
-}
type alias AllDocs value = { offset : Bool
                           , totalRows : Int
                           , docs : List (Doc value)
                           }
                             
                             
{- Successful database deletion.
-}
type SuccessDestroy = Success
                    
                    
{- Failure of a database deletion.
-}
type FailDestroy = Failed
                 
                      
{- Represents an adapter.
-}
type Adapter = Idb
             | LevelDb
             | WebSql
             | Http
             | Auto


{-Represents the set of options used when initiating a Pouchdb/Couchdb database.
-}
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
                   

{-A helper function that returns the minimum set of options used when initiating a Pouchdb/Couchdb database.
 -}
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


{- Represents a helper function to use when initiating a database. If used, it sets the username and password of the database in the options. Should be chained after dbOptions or any other database helper functions.
-}
auth : String->String->Options->Options
auth username password options=
    { options | username=Just username, password=Just password}

  
{- Represents a helper function to use when initiating a database. If used, it sets whether a ajax cache should be used for the remote database. Should be chained after dbOptions or any other database helper functions.
-}
ajaxCache : Bool->Options->Options
ajaxCache cache options =
  { options | cache=Just cache}

  
{- Represents a helper function to use when initiating a database. If used, it sets whether ajax headers should be used for the remote database. Should be chained after dbOptions or any other database helper functions.
-}      
ajaxHeaders : Value->Options->Options
ajaxHeaders headers options =
  { options | headers=Just headers}
    

{- Represents a helper function to use when initiating a database. If used, it sets whether ajax credentials should be used for the remote database. Should be chained after dbOptions or any other database helper functions.
-}
ajaxWithCredentials : Bool->Options->Options
ajaxWithCredentials withCredentials options =
  { options | withCredentials=Just withCredentials}
    

{- Represents a helper function to use when initiating a database. If used, it sets automatic compaction for the database. Should be chained after dbOptions or any other database helper functions.
-}
autoCompaction : Bool->Options->Options
autoCompaction autoCompaction options =
  {options | auto_compaction=Just autoCompaction}
    
  
{- Represents a helper function to use when initiating a database. If used, it sets  how many old revisions are tracked in the database. Should be chained after dbOptions or any other database helper functions.
-}
revsLimit : Int->Options->Options
revsLimit limit options =
  {options | revs_limit=Just limit}
    

{- Represents a helper function to use when initiating a database. If used, and if set to True, will not create the database if it does not already exist. Should be chained after dbOptions or any other database helper functions.
-}
skipSetup : Bool->Options->Options
skipSetup skip options =
  { options | skip_setup=Just skip}
    

{- Represents a helper function to use when initiating a database. If used, it setsthe 'Adapter' for the database. Should be chained after dbOptions or any other database helper functions.
-}
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
put : Pouchdb -> Value -> Maybe String-> Task Fail Put
put =
  Native.ElmPouchdb.put
        

{- Post a document in the database.
-}
post : Pouchdb -> Value -> Task Fail Post
post =
  Native.ElmPouchdb.post

        
{- Remove a document from the database.
-}
remove : Pouchdb -> DocId -> RevId-> Task Fail Remove
remove db id rev=
  Native.ElmPouchdb.removeById db id (Just rev)


{- Retrieve a document from the database.
-}  
getValue : Pouchdb -> DocRequest -> Task Fail (Doc Value)
getValue db req =
  Native.ElmPouchdb.get db req

  
{- Retrieve a document from the database.
-}  
get : Pouchdb->Json.Decoder value-> DocRequest -> Task Fail (Doc value)
get db decoder req =
  Native.ElmPouchdb.get db req `andThen` (decode decoder)

  
{- internal decode helper function.
-}
decode: Json.Decoder value -> Doc Value -> Task Fail (Doc value)
decode decoder doc =
  case fromValue decoder doc of
      Result.Ok value -> 
        succeed value
      Result.Err error ->
        fail error
  
{- Helper function for decoding Doc
-}       
fromValue : Json.Decoder value -> Doc Value -> Result Fail (Doc value)
fromValue decoder doc =
  let
    valDoc =  case doc.doc of
                Just val -> Json.decodeValue decoder val
                Nothing -> Result.Err "trying to decode empty payload"
  in
    case valDoc of
      Result.Ok value -> 
        Result.Ok { id=doc.id
                  , rev=doc.rev
                  , doc=Just value
                  , revisions=doc.revisions
                  , conflicts=doc.conflicts
                  , sequence=doc.sequence
                  , key=doc.key
                  }
      Result.Err error ->
        Result.Err { status= 0
                   , name= "empty payload"
                   , message= error
                   }                        

        
{- Fetch within all documenst in the databse.
-}
allDocs : Pouchdb -> AllDocsRequest -> Task Fail (AllDocs value)
allDocs db req =
  Native.ElmPouchdb.allDocs db req

        
{- Query the database.
-}
query : Pouchdb -> QueryRequest -> Task Fail (AllDocs value)
query db req =
  Native.ElmPouchdb.query db req
