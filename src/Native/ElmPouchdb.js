'use strict';

//var _powet$elm_pouchdb$Native_ElmPouchdb = function() {
var _user$project$Native_ElmPouchdb = function() {
  
  var nativeBinding = _elm_lang$core$Native_Scheduler.nativeBinding;
  var succeed = _elm_lang$core$Native_Scheduler.succeed;
  var fail = _elm_lang$core$Native_Scheduler.fail;
  var Nothing = _elm_lang$core$Maybe$Nothing;
  var Just = _elm_lang$core$Maybe$Just;
  var EmptyList = _elm_lang$core$Native_List.Nil;
  var Cons = _elm_lang$core$Native_List.Cons; 
  var rawSpawn = _elm_lang$core$Native_Scheduler.rawSpawn;
  var toArray = _elm_lang$core$Native_List.toArray;
  
  function ctorBool(val){
    return val?{ ctor: 'True' }:{ ctor: 'False' };
  }

  function ctorFailed(){
    ctor: 'Failed';
  }
  
  function toFail(error){
    return {
      status: error.status,
      name: error.name,
      message: error.message,
      reason: error.reason
    };
  }
  
  function toSuccessPut(response){
    return { id: response.id
             , rev: response.rev
           };
  }
 
  function setAjax(src,target){
    if( src.ctor ==='Just'){
      target.ajax={};
      if (src._0.cache.ctor==='Just'){
        target.ajax.cache=src._0.cache._0;
      }
      if (src._0.headers.ctor==='Just'){
        target.ajax.headers=src._0.headers._0;
      }
      if (src._0.withCredentials.ctor==='Just'){
        target.ajax.withCredentials=src._0.withCredentials._0;
      }
    }
  }

  function setAdapter(src,target){
    if( src.ctor ==='Idb'){
      target.adapter= 'idb';
    }
    if( src.ctor ==='LevelDb'){
      target.adapter= 'leveldb';
    }
    if( src.ctor ==='WebSql'){
      target.adapter= 'websql';
    }
    if( src.ctor ==='Http'){
      target.adapter= 'http';
    }
  }
  
  function setMaybe(src, target, attr){
    if (src.ctor ==='Just') {
      target[attr]=src._0;
    } else {
      target[attr]=undefined;
    }
  }
  
  function setMaybeComposed(src, target, composition, attr){
    if (src.ctor ==='Just') {
      if (target[composition] === undefined){
        target[composition] = {};
      }
      target[composition][attr]=src._0;
    }
  }

  function toDbOptions(opt){
    var options = {};
    setMaybe (opt.auto_compaction,options, 'auto_compaction');
    setAdapter(opt,opt.adaptor);
    setMaybe(opt.revs_limit,options,'revs_limit');
    setMaybeComposed(opt.username,options,'auth','username');
    setMaybeComposed(opt.password,options,'auth','password');
    setMaybeComposed(opt.cache,options,'ajax','cache');
    setMaybeComposed(opt.headers,options,'ajax','headers');
    setMaybeComposed(opt.withCredentials,options,'ajax','withCredentials');
    setMaybe(opt.skip_setup,options, 'skip_setup');
    return options;
  }
  
  function db(name,opt){
    var options = toDbOptions(opt);
    var rv = new PouchDB(name,options);
    return rv;
  };

  function toRevsGet(revisons){
    var revs = EmptyList;
    for (var property in revisons.ids) {
      var rev = {};
      rev.sequence= revisons.start-property;
      rev.uuid = revisons.ids[property];
      revs = Cons(rev, revs);
    }
    return revs;
  }

  function toSuccessGet(response) {
    var returnVal = {};
    returnVal.id=response._id;
    returnVal.rev=Just(response._rev);
    var doc = {};
    returnVal.conflicts = Nothing;
    returnVal.revisions = Nothing;
    for (var property in response) {
      if (property === "_conflicts") {
        returnVal.conflicts = Just(response[property]);
      } else if (property === "_revisions") {
        returnVal.revisions = Just(toRevsGet(response[property]));
      } else
        doc[property] = response[property];
    }
    returnVal.doc = Just(doc);
    returnVal.sequence = Nothing;
    return returnVal;  
  }

  function toSuccessAllDocs(response) {
    var returnVal = {};
    returnVal.offset=response.offset;
    returnVal.totalRows=response.total_rows;
    returnVal.docs=EmptyList;
    for (var docRef in response.rows){
      var respDoc=response.rows[docRef];
      if (respDoc.error===undefined){
        var doc = { id : respDoc.id
                    , rev : Just(respDoc.value.rev)
                    , doc : (respDoc.doc)?Just(respDoc.doc):Nothing
                    , revisions : Nothing
                    , conflicts : Nothing
                    , sequence : Nothing
                    , key : Nothing
                  };
        returnVal.docs = Cons(doc,returnVal.docs);
      }
    }
    return returnVal;  
  }

  function toSuccessQuery(response) {
    var returnVal = {};
    returnVal.offset=response.offset;
    returnVal.totalRows=response.total_rows;
    returnVal.docs=EmptyList;
    for (var docRef in response.rows){
      var respDoc=response.rows[docRef];
      var doc = { id : respDoc.id
                  , rev : respDoc.doc?Just(respDoc.doc._rev):Nothing
                  , doc : (respDoc.doc)?Just(respDoc.doc):Nothing
                  , revisions : Nothing
                  , conflicts : Nothing
                  , sequence : Nothing
                  , key: (respDoc.key)?Just(respDoc.key):Nothing
                };
      returnVal.docs = Cons(doc,returnVal.docs);
    }
    return returnVal;
  }

  function destroy(db){
    return nativeBinding(function(callback){
      db.destroy(function(err, response) {
        if (err) { return callback(fail({ ctor: 'Failed' })); }
        return callback(succeed({ ctor: 'Success' }));
      });
    });
  };

  function destructiveReset(db,name){
    var check = function (name,callback){
      var db=new PouchDB(name);
      db.allDocs(function(err, info) {
        if (err) { return callback(fail({ ctor: 'Failed' })); }
        return callback(succeed(db));
      });
    };
    return nativeBinding(function(callback){
      db.destroy(function(err, response) {
        if (err) { return callback(fail({ ctor: 'Failed' })); }
        return check(name,name,callback);
      });
    });
    };
  

  function put(db,doc,rev){
    return nativeBinding(function(callback){
      if (rev.ctor === 'Just') {
        doc._rev = rev._0;
      }
      db.put( doc, function(err,response) {
        if (err) { return callback(fail(toFail(err))); }
        return callback(succeed(toSuccessPut(response)));
      });
    });
  };
    
  function post(db,doc){
    return nativeBinding(function(callback){
      db.post( doc, function(err,response) {
        if (err) { return callback(fail(toFail(err))); }
        return callback(succeed(toSuccessPut(response)));
      });
    });
  }

  function remove(db,doc,rev){
    var devaredDoc = db;
    devaredDoc._devared=true;
    put(db,devaredDoc,rev);
  };

  function removeById(db,id,rev){
    var devaredDoc = { _id:id
                       , _devared:true};
    
    put(db,devaredDoc,rev);
  };

  function toGetOptions(req){
    var options= { };
    setMaybe(req.rev,options,'rev');
    setMaybe(req.revs,options,'revs');
    setMaybe(req.conflicts,options,'conflicts');
    setMaybe(req.attachments,options,'attachments');
    setMaybe(req.binary,options,'binary');
    return options;
  }
  
  function get(db,req) {
    var id = req.id;
    var options = toGetOptions(req);
    return nativeBinding(function(callback){
      db.get(id, options,function(err, doc) {
        if (err) { return callback(fail(toFail(err))); }
        return callback(succeed(toSuccessGet(doc)));
      });
    });
  }
  function replaceAny(item){
    if (item==="{}"){
      return {};
    }
    else {
      return item;
    }
  }
  
  function toAllDocsOptions(req){
    var options = {};
    setMaybe(req.include_docs,options,'include_docs');
    setMaybe(req.conflicts,options,'conflicts');
    setMaybe(req.attachments,options,'attachments');
    setMaybe(req.descending,options,'descending');
    setMaybe(req.skip,options,'skip');
    setMaybe(req.startkey,options,'startkey');
    if (options.startkey) {
      options.startkey = toArray(options.startkey);
      options.startkey = options.startkey.map(replaceAny);
      if(options.startkey.length==1){
        options.startkey =options.startkey[0];
      }
    }
    setMaybe(req.endkey,options,'endkey');
    if (options.endkey) {
      options.endkey = toArray(options.endkey);
      options.endkey = options.endkey.map(replaceAny);
      if(options.endkey.length==1){
        options.endkey =options.endkey[0];
      }
    }
    
    if (options.startkey && options.endkey){
      if(Array.isArray(options.startkey) && !Array.isArray(options.endkey)){
        options.endkey=[options.endkey];
      }
      if(Array.isArray(options.endkey) && !Array.isArray(options.startkey)){
        options.startkey=[options.startkey];
      } 
    }

    
    setMaybe(req.inclusive_end,options,'inclusive_end');
    setMaybe(req.limit,options,'limit');
    setMaybe(req.keys,options,'keys');
    if (options.keys) {
      options.keys = toArray(options.keys);
    }
    return options;
  }
  
  function allDocs(db,req) {
    var options = toAllDocsOptions(req);
    return nativeBinding(function(callback){
      db.allDocs(options,function(err, docs) {
        if (err) { return callback(fail(toFail(err))); }
        return callback(succeed(toSuccessAllDocs(docs)));
      });
    });
  }

  function setStale(stale,options){
    options.stale=undefined;
    if ( stale.ctor === 'Just') {
      switch (stale.ctor) {
      case 'Ok':
        options.stale= 'ok';
        break;
      case 'UpdateAfter':
        options.stale= 'update_after';
        break;
      }
    } 
    return options;
  }
  
  function setReduce(reduce,options){
    options.reduce=undefined;
    switch (reduce.ctor) {
    case 'Sum': 
      options.reduce='_sum';
      break;
    case 'Counts': 
      options.reduce='_counts';
      break;
    case 'Stats': 
      options.reduce='_stats';
      break;
    }
    return options;
  }

  function getFun(fun){
    var returnValue;
      switch (fun.ctor) {
      case 'MapReduce':
        returnValue = eval(fun._0);
        break;
      case 'Map':
        returnValue = Function ('doc',fun._0);
        break;
      case 'ViewName': 
        returnValue = fun._0;
        break;
      }
    return returnValue;
  };

  function setGroupLevel(group_level, options){
    options.group=undefined;
    setMaybe(group_level,options,'group_level');
    if (options.group_level){
      options.group=true;
    }
  }
  
  function query(db,opt) {
    var fun = getFun(opt.fun);
    var options = {};
    setMaybe(opt.include_docs,options,'include_docs');
    setMaybe(opt.conflicts,options,'conflicts');
    setMaybe(opt.attachments,options,'attachments');
    setMaybe(opt.descending,options,'descending');
    setMaybe(opt.skip,options,'skip');
    setMaybe(opt.startkey,options,'startkey');
    if (options.startkey) {
      options.startkey = toArray(options.startkey);
      options.startkey = options.startkey.map(replaceAny);
      if(options.startkey.length==1){
        options.startkey =options.startkey[0];
      }
    }
    setMaybe(opt.endkey,options,'endkey');
    if (options.endkey) {
      options.endkey = toArray(options.endkey);
      options.endkey = options.endkey.map(replaceAny);
      if(options.endkey.length==1){
        options.endkey =options.endkey[0];
      }
    }
    
    if (options.startkey && options.endkey){
      if(Array.isArray(options.startkey) && !Array.isArray(options.endkey)){
        options.endkey=[options.endkey];
      }
      if(Array.isArray(options.endkey) && !Array.isArray(options.startkey)){
        options.startkey=[options.startkey];
      } 
    }
     
    setMaybe(opt.inclusive_end,options,'inclusive_end');
    setMaybe(opt.limit,options,'limit');
    //setMaybe(opt.key,options,'key');
    setMaybe(opt.keys,options,'keys');
    if (options.keys) {
      options.keys = toArray(options.keys);
    }
    setStale(opt.stale,options);
    setReduce(opt.reduce,options);
    setGroupLevel(opt.groupLevel,options);
   
    return nativeBinding(function(callback){
      db.query(fun,options,function(err, docs) {
        if (err) { return callback(fail(toFail(err))); }
        return callback(succeed(toSuccessQuery(docs)));
      });
    });
  }
  
  return { db: F2(db)
           , destructiveReset:F2(destructiveReset)
           , destroy: destroy
           , get: F2(get)
           , allDocs: F2(allDocs)
           , query: F2(query)
           , put: F3(put)
           , post: F2(post)
           , remove:F3(remove)
           , removeById: F3(remove)
         };
}();
