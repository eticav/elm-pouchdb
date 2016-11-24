module Pouchdb exposing ( JSFun(ViewName, Map, MapReduce)
                        , DocId
                        , RevId
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
                        , destructiveReset
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
                        , Adapter(Idb, LevelDb, WebSql, Http, Auto)
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
                        , descending
                        , skip
                        , limit
                        , inclusive_end
                        , endkey
                        , startkey
                        , include_docs
                        )


{-| This module provides an elm mapping to the great [pouchdb](https://pouchdb.com/) javascript library. Most of the functionalities have been mapped, it therefore provides a lot of functionalities among which: [put](#put), [post](#post), [get](#get), [allDocs](#allDocs), [query](#query), listening to changes and syncing with other pouchdb or couchdb

# Database operations
@docs Pouchdb, Options, db, SuccessDestroy, FailDestroy, destroy, destructiveReset

## Database helper function
@docs dbOptions, auth, ajaxCache, Adapter, adapter, skipSetup, revsLimit, autoCompaction, ajaxWithCredentials, ajaxHeaders


# Document operations
## Put, Post and Remove
@docs DocId, RevId, Fail, Put, put, Post, post, Remove, remove

## Get and all_docs
@docs DocRequest, request, Doc, get, getValue, fromValue, AllDocs, AllDocsRequest, allDocsRequest, allDocs

## Query
@docs JSFun, QueryRequest, queryRequest, query

## Requests helper function
@docs revs, conflicts, attachments, binary, keys, descending, skip, limit, inclusive_end, endkey, startkey, include_docs
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

{-| The internal representation of PouchDB/CouchDB databases. Use the [db](#db) function for creating a local or a remote database.

    type alias Model =
      { local : Pouchdb
      , remote : Pouchdb
      }
    
    initialModel : Model
    initialModel =
      let
        local = db "DB-Test" dbOptions
        remote = db "https://xxxxxx.cloudant.com/db-test"
          (dbOptions
            |> auth "myUserName" "myPassword"
            |> ajaxCache True)
      in 
        { local = local
        , remote = remote
        }
-}
type Pouchdb = Pouchdb

{-| Represents the DocId.
-}
type alias DocId = String


{-| Represents the RevId.
-}
type alias RevId = String

                 
{-| Represents a doc request used by the [get](#get) function. You should use the [request](#request) function for minimal setup.
-}
type alias DocRequest = { id: DocId
                        , rev: Maybe RevId
                        , revs: Maybe Bool
                        , conflicts : Maybe Bool
                        , attachments : Maybe Bool
                        , binary: Maybe Bool
                        }

                     
{-| A helper function for creating a minimum [DocRequest](#DocRequest). The helper function [revs](#revs), [conflicts](#conflicts), [attachments](#attachments) and [revsbinary](#binary) are provided to complete the doc request. Use them instead of accessing directly to the record.
-}
request : DocId->Maybe RevId->DocRequest
request id rev = { id = id
                 , rev = rev
                 , revs = Maybe.Nothing
                 , conflicts = Maybe.Nothing
                 , attachments = Maybe.Nothing
                 , binary = Maybe.Nothing
                 }


{-| Represents a helper function for including revision history of the document.
-}
revs : Bool->DocRequest->DocRequest
revs x request =
  {request|revs = Just x}

    
{-| Represents a helper function to use when doing requests. If used, conflicting leaf revisions will be attached in a conflicts list.
-}
conflicts : Bool->{a|conflicts:Maybe Bool}->{a|conflicts:Maybe Bool}
conflicts x request =
  {request|conflicts = Just x}

    
{-| Represents a helper function to use when doing requests. If used, attachement data will be retreived.
-}  
attachments : Bool->{a|attachments:Maybe Bool}->{a|attachments:Maybe Bool}
attachments x request =
  {request|attachments = Just x}

    
{-| Represents a helper function to use when doing requests. If used jointle with attachments, it returns data as Blob/Buffers. Not tested! Use at your own risk.
-}    
binary : Bool->DocRequest->DocRequest
binary x request =
  {request|binary = Just x}
  
  
{-| Represents a request used by the function [all](#all). You should use the [allDocsRequest](#allDocsRequest) function for minimal setup.
-}
type alias AllDocsRequest = { include_docs : Maybe Bool
                            , conflicts : Maybe Bool
                            , attachments : Maybe  Bool
                            , startkey : Maybe (List DocId)
                            , endkey : Maybe (List DocId)
                            , inclusive_end : Maybe Bool
                            , limit : Maybe Int
                            , skip : Maybe Int
                            , descending : Maybe Bool
                            , keys : Maybe (List DocId)
                            }

                          
{-| A helper function for creating a miniumum [AllDocsRequest](#AllDocsRequest). The helper function [include_docs](#include_docs), [conflicts](#conflicts), [attachments](#attachments), [startkey](#startkey), [endkey](#endkey), [inclusive_end](#inclusive_end), [limit](#limit), [skip](#skip), [descending](#descending) and [keys](#keys) are provided to complete the query request. Use them instead of accessing directly to the record.
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
                 , keys = Maybe.Nothing
                 }


{-| Represents a helper function to use when doing requests. If used, include the document itself.
-}
include_docs : Bool->{a|include_docs:Maybe Bool}->{a|include_docs:Maybe Bool}
include_docs x request =
  {request|include_docs = Just x}
    
    
{-| Represents a helper function to use when doing requests. If used, get documents with IDs in a certain range starting at [startkey](#startkey).
-}
startkey : List DocId->
           {a|startkey:Maybe (List DocId), keys:Maybe (List DocId) }->
           {a|startkey:Maybe (List DocId), keys:Maybe (List DocId) }
startkey x request =
  {request|startkey = Just x, keys=Nothing}
    

{-| Represents a helper function to use when doing requests. If used, get documents with IDs in a certain range ending at [endkey](#endkey).
-}
endkey : List DocId->
           {a|endkey:Maybe (List DocId), keys:Maybe (List DocId) }->
           {a|endkey:Maybe (List DocId), keys:Maybe (List DocId) }
endkey x request =
  {request|endkey = Just x, keys=Nothing}

    
{-| Represents a helper function to use when doing requests. If used, includes the [endkey](#endkey) document.
-}
inclusive_end : Bool->
           {a|inclusive_end:Maybe Bool, keys:Maybe (List DocId) }->
           {a|inclusive_end:Maybe Bool, keys:Maybe (List DocId) }
inclusive_end x request =
  {request|inclusive_end = Just x, keys=Nothing}
    

{-| Represents a helper function to use when doing requests. If used, sets the maximum number of documents to return.
-}
limit : Int->{a|limit:Maybe Int}->{a|limit:Maybe Int}
limit x request =
  {request|limit = Just x}
    
    
{-| Represents a helper function to use when doing requests. If used, sets the number of docs to skip before returning. Pouchdb documentation indicates poor performance, use [startkey](#startkey)/[endkey](#endkey) instead.
-}
skip : Int->{a|skip:Maybe Int}->{a|skip:Maybe Int}
skip x request =
  {request|skip = Just x}
    

{-| Represents a helper function to use when doing requests. If used, reverses the order of the output documents.
-}
descending : Bool->{a|descending:Maybe Bool}->{a|descending:Maybe Bool}
descending x request =
  {request|descending = Just x}    
    
{-| Represents a helper function to use when doing requests. If used, the request only retruns the documents with the list of keys.
-}
keys : List DocId->
           {a| keys:Maybe (List DocId), startkey:Maybe (List DocId), endkey:Maybe (List DocId) }->
           {a| keys:Maybe (List DocId), startkey:Maybe (List DocId), endkey:Maybe (List DocId) }
keys x request =
  {request|keys = Just x, startkey=Nothing, endkey=Nothing}
  

{-| Represents a JS Map/Reduce function, a JS Map function or a view name. It is used within the [QueryRequest](#QueryRequest) object.
-}
type  JSFun = MapReduce String
            | Map String
            | ViewName String
              

{-| Any of the standard reduce functions among which sum, count or stats, or a JS reduce function.
-}
type Reduce = Sum
            | Count
            | Stats
            | Fun Value
              

{-| Represents a Stale Object.
-}         
type Stale = Ok
           | UpdateAfter
             
            
{-| Represents Query request object to be used in the query function. You should use the [queryRequest](#queryRequest) function for minimal setup.
-}
type alias QueryRequest = { fun : JSFun
                          , reduce : Maybe Reduce
                          , include_docs : Maybe Bool
                          , conflicts : Maybe Bool
                          , attachments : Maybe  Bool
                          , startkey : Maybe (List DocId)
                          , endkey : Maybe (List DocId)
                          , inclusive_end : Maybe Bool
                          , limit : Maybe Int
                          , skip : Maybe Int
                          , descending : Maybe Bool
                          , groupLevel : Maybe Int               
                          , keys : Maybe (List DocId)
                          , stale : Maybe Stale
                          }
                        
                        
{-| A helper function for creating a default [QueryRequest](#QueryRequest). The helper function [reduce](#reduce), [conflicts](#conflicts), [attachments](#attachments), [startkey](#startkey), [endkey](#endkey), [inclusive_end](#inclusive_end), [limit](#limit), [skip](#skip), [descending](#descending), [groupLevel](#groupLevel), [key](#key), [keys](#keys), [stale](#stale) are provided to complete the query request. Use them instead of accessing directly to the record.
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
                   , keys = Maybe.Nothing
                   , stale = Maybe.Nothing
                   }
                  

{-| When a function fails, this record will be received.
-}
type alias Fail = { status: Int
                  , name: String
                  , message: String
                  }

                
{-| When a put  succeeds , this record will be received.
-}
type alias Put = { id: DocId
                 , rev: RevId
                 }

               
{-| When a post  succeeds , this record will be received.
-}
type alias Post = { id: DocId
                 , rev: RevId
                 }

                
{-| When a remove  succeeds , this record will be received.
-}
type alias Remove = { id: DocId
                    , rev: RevId
                    }
                      
                      
{-| Represents a revision.
-}
type alias Revision = { sequence : Int
                      , uuid  : RevId }
                    
                    
{-| The record received when the datavase is queried with [get](#get), [all](#all), or [changes](#changes) functions.
-}
type alias Doc value = { id: DocId
                       , rev: Maybe RevId
                       , doc : Maybe value
                       , revisions : Maybe (List Revision)
                       , conflicts : Maybe Value
                       , sequence : Maybe Int
                       , key : Maybe Value
                       }


{-| When a [all](#all) or [query](#query) succeeds , this record will be received. Note, its a holder for a list of [Doc](#Doc).
-}
type alias AllDocs value = { offset : Bool
                           , totalRows : Int
                           , docs : List (Doc value)
                           }
                             
                             
{-| Successful database deletion.
-}
type SuccessDestroy = Success
                    
                    
{-| Failure of a database deletion.
-}
type FailDestroy = Failed
                 
                      
{-| Represents an adapter.
-}
type Adapter = Idb
             | LevelDb
             | WebSql
             | Http
             | Auto


{-|Represents the set of options used when initiating a Pouchdb/Couchdb database. You should use the [dbOptions](#dbOptions) to start with and use the helpers functions to modify any default items.

    remote = db "https://xxxxxx.cloudant.com/db-test"
          (dbOptions
            |> auth "myUserName" "myPassword"
            |> ajaxCache True)

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
                   

{-|A helper function that returns the default set of options used when initiating a Pouchdb/Couchdb database.

    -- for a local databse with all defaulted options
    local = db "DB-Test" dbOptions

    -- for a remote database with some modified options
    remote = db "https://xxxxxx.cloudant.com/db-test"
          (dbOptions
            |> auth "myUserName" "myPassword"
            |> ajaxCache True)

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


{-| Represents a helper function to use when initiating a database. If used, it sets the username and password of the database in the options. Should be chained after [dbOptions](#dbOptions) or any other database helper function.
-}
auth : String->String->Options->Options
auth username password options=
    { options | username=Just username, password=Just password}

  
{-| Represents a helper function to use when initiating a database. If used, it sets whether a ajax cache should be used for the remote database. Should be chained after [dbOptions](#dbOptions) or any other database helper function.
-}
ajaxCache : Bool->Options->Options
ajaxCache cache options =
  { options | cache=Just cache}

  
{-| Represents a helper function to use when initiating a database. If used, it sets whether ajax headers should be used for the remote database. Should be chained after [dbOptions](#dbOptions) or any other database helper function.
-}      
ajaxHeaders : Value->Options->Options
ajaxHeaders headers options =
  { options | headers=Just headers}
    

{-| Represents a helper function to use when initiating a database. If used, it sets whether ajax credentials should be used for the remote database. Should be chained after [dbOptions](#dbOptions) or any other database helper function.
-}
ajaxWithCredentials : Bool->Options->Options
ajaxWithCredentials withCredentials options =
  { options | withCredentials=Just withCredentials}
    

{-| Represents a helper function to use when initiating a database. If used, it sets automatic compaction for the database. Should be chained after [dbOptions](#dbOptions) or any other database helper function.
-}
autoCompaction : Bool->Options->Options
autoCompaction autoCompaction options =
  {options | auto_compaction=Just autoCompaction}
    
  
{-| Represents a helper function to use when initiating a database. If used, it sets  how many old revisions are tracked in the database. Should be chained after [dbOptions](#dbOptions) or any other database helper function.
-}
revsLimit : Int->Options->Options
revsLimit limit options =
  {options | revs_limit=Just limit}
    

{-| Represents a helper function to use when initiating a database. If used, and if set to True, will not create the database if it does not already exist. Should be chained after [dbOptions](#dbOptions) or any other database helper function.
-}
skipSetup : Bool->Options->Options
skipSetup skip options =
  { options | skip_setup=Just skip}
    

{-| Represents a helper function to use when initiating a database. If used, it sets the 'Adapter' for the database. Should be chained after [dbOptions](#dbOptions) or any other database helper function.
-}
adapter : Adapter->Options->Options
adapter adapt options =
  { options | adapter=adapt}
    

{-| Create a new database. Refer to [Pouchdb](#Pouchdb) for example of usage.
-}
db : a -> Options -> Pouchdb
db name options =
  Native.ElmPouchdb.db name options

    
{-| Recreate a database after destroying it. This function is buggy due to a Pouchdb bug. I recommend not using it... 
-} -- TODO: probably a delay is required atfer deletion...
destructiveReset : Pouchdb-> name -> Task FailDestroy Pouchdb 
destructiveReset db name  =
  Native.ElmPouchdb.destructiveReset db name
        
        
{-| Delete an existing database.
-}
destroy : Pouchdb-> Task FailDestroy SuccessDestroy
destroy db =
  Native.ElmPouchdb.destroy db
        

{-| Post a document in the database.

    -- as usual declare the model
    type alias Model = { localDb : Pouchdb
                       , returnMsg : Maybe String
                       }
    -- declare the Messages
    type Message = PutButton
             | PutError Pouchdb.Fail
             | PutSuccess Pouchdb.Put

    -- a bit of encoding
    encoder : String->String->Encode.Value
    encoder id val =
       Encode.object
          [ ("_id", Encode.string id)
          , ("val", Encode.string val)
          ]
    

    -- PutButton was sent by a button, see how a put task is now send.
    
    update : Message -> Model -> (Model, Cmd Message)
    update msg model =
      case msg of
        PutButton->
          let 
            task = (Pouchdb.put model.localDb (encoder "id2" "hello") Nothing)
            cmd = Task.perform PutError PutSuccess task
          in
           (model,cmd)
        PutSuccess msg->
          let 
            newMsg = String.append "Successfully put in db with rev = " msg.rev
          in
            ({model|returnMsg=Just newMsg}, Cmd.none)
        PutError msg->
          let
            newMsg = String.append "Error putting in db with message = " msg.message
          in
           ({model|returnMsg=Just newMsg}, Cmd.none)
     ...

-}
put : Pouchdb -> Value -> Maybe String-> Task Fail Put
put =
  Native.ElmPouchdb.put
        

{-| Post a document in the database. Refer to the [Put example](#Put) and modify to fit with Post.
-}
post : Pouchdb -> Value -> Task Fail Post
post =
  Native.ElmPouchdb.post


{-| Remove a document from the database. Refer to the [Put example](#Put) and modify to fit with Remove. In the background, Remove is implemented by calling [Put](#Put) with the flag _delete = true, it therefore really works like [Put](#Put).

-}
remove : Pouchdb -> DocId -> RevId-> Task Fail Remove
remove db id rev=
  Native.ElmPouchdb.removeById db id (Just rev)


{-| Retrieve a document from the database. Returns a Value that needs to be decoded. This function is called by [Get](#Get), they really work the same way, the only difference is that it needs decoding. You may jointly want to use [fromValue](#fromValue)

    Sample code taken from [get](#get) function and modified for using Values. Note that the [fromValue](#fromValue] function is used. 

    type Message =
             GetSuccess (Pouchdb.Doc Value)
             | GetError Pouchdb.Fail
             ...
               
    type alias Model = { localDb : Pouchdb
                       , doc : Maybe DocModel
                       }
                       
    decoder : Decoder DocModel
    decoder = object2 DocModel
                ("_id":=Decode.string)
                ("val":=Decode.string)
    
    update : Message -> Model -> (Model, Cmd Message)
    update msg model =
      case msg of
        PutButton->
          let
            req= Pouchdb.request "id2" Nothing
                   |> Pouchdb.conflicts True
                   -- Conflicts option not usefull here, but just a show case!
            task = Pouchdb.getValue model.localDb req
            cmd = Task.perform GetError GetSuccess task
          in
            (model,cmd)
        GetSuccess msg->
          case msg.doc of
            Just value ->
            let
               case fromValue decoder value of
                 Ok doc -> 
                   ({model|doc = Just doc}, Cmd.none)
                 Err _-> (model, Cmd.none)
            Nothing ->
              (model, Cmd.none)
        GetError msg->
            -- handle fail here
            (model, Cmd.none)
-}
getValue : Pouchdb -> DocRequest -> Task Fail (Doc Value)
getValue db req =
  Native.ElmPouchdb.get db req

  
{-| Retrieve a document from the database.

Full code available in Example/GetExample.elm

    type Message =
             PutButton
             | GetSuccess (Pouchdb.Doc DocModel)
             | GetError Pouchdb.Fail
             ...
               
    type alias Model = { localDb : Pouchdb
                       , doc : Maybe DocModel
                       }
                       
    decoder : Decoder DocModel
    decoder = object2 DocModel
                ("_id":=Decode.string)
                ("val":=Decode.string)
    
    update : Message -> Model -> (Model, Cmd Message)
    update msg model =
      case msg of
        PutButton->
          let
            req= Pouchdb.request "id2" Nothing
                   |> Pouchdb.conflicts True
                   -- Conflicts option not usefull here, but just a show case!
            task = Pouchdb.get model.localDb decoder req
            cmd = Task.perform GetError GetSuccess task
          in
            (model,cmd)
        GetSuccess msg->
          case msg.doc of
            Just doc ->
              ({model|doc = Just doc}, Cmd.none)
            Nothing ->
              (model, Cmd.none)
        GetError msg->
            -- handle fail here
            (model, Cmd.none)
            
-}  
get : Pouchdb->Json.Decoder value-> DocRequest -> Task Fail (Doc value)
get db decoder req =
  Native.ElmPouchdb.get db req |> andThen (decode decoder)


{-| internal decode helper function.
-}
decode: Json.Decoder value -> Doc Value -> Task Fail (Doc value)
decode decoder doc =
  case fromValue decoder doc of
      Result.Ok value -> 
        succeed value
      Result.Err error ->
        fail error
  
{-| Helper function for decoding Doc. Refer to [getValue](#getValue) for an example.
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


{-| Fetch within all documents in the database.

Full code available in Example/AllDocsExample.elm

    type alias DocModel = { id :String
                          , val : String }
    
    type Message = PutButton
                 | AllDocsSuccess (Pouchdb.AllDocs Value)
                 | AllDocsError Pouchdb.Fail
                 ...
               
    type alias Model = { localDb : Pouchdb
                       , docs : List DocModel
                       }
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
                 |> Pouchdb.include_docs True
            task = Pouchdb.allDocs model.localDb req
            cmd = Task.perform AllDocsError AllDocsSuccess task
          in
            (model,cmd)
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
         ...

-}
allDocs : Pouchdb -> AllDocsRequest -> Task Fail (AllDocs value)
allDocs db req =
  Native.ElmPouchdb.allDocs db req

        
{-| Query the database.
Refer to allDocs code example, code should be very similar.

Warning: This functionality is not supported by cloudant.

-}
query : Pouchdb -> QueryRequest -> Task Fail (AllDocs value)
query db req =
  Native.ElmPouchdb.query db req
