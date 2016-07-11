'use strict';

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
  
  function getMaybeValue(val,d){
    if ( val.ctor === 'Just') {return val._0;}
    return d;
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
    let options = {};
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
    let options = toDbOptions(opt);
    var rv = new PouchDB(name,options);
    //rv.on('error', function (err) { debugger; });
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
    let returnVal = {};
    returnVal.id=response._id;
    returnVal.rev=Just(response._rev);
    let doc = {};
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
    // returns SuccessGetAllDocs
    let returnVal = {};
    //return response;
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
    // returns SuccessGetAllDocs
    let returnVal = {};
    //return response;
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

  function put(db,doc,rev){
    if (rev.ctor === 'Just'){
      return nativeBinding(function(callback){
        db.put( doc, doc.id, rev._0, function(err,response) {
          if (err) { return callback(fail(toFail(err))); }
          return callback(succeed(toSuccessPut(response)));
        });
      });
    }else
      return nativeBinding(function(callback){
        db.put( doc, function(err,response) {
          if (err) { return callback(fail(toFail(err))); }
          return callback(succeed(toSuccessPut(response)));
        });
      });
  }

  function post(db,doc){
    return nativeBinding(function(callback){
      db.post( doc, function(err,response) {
        if (err) { return callback(fail(toFail(err))); }
        return callback(succeed(toSuccessPut(response)));
      });
    });
  }

  function remove(db,doc,rev){
    var deletedDoc = db;
    deletedDoc._deleted=true;
    put(db,deletedDoc,rev);
  };

  function removeById(db,id,rev){
    var deletedDoc = { _id:id
                       , _deleted:true};
    
    put(db,deletedDoc,rev);
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
    let options = toGetOptions(req);
    return nativeBinding(function(callback){
      db.get(id, options,function(err, doc) {
        if (err) { return callback(fail(toFail(err))); }
        return callback(succeed(toSuccessGet(doc)));
      });
    });
  }

  function allDocs(db,req) {
    let key = getMaybeValue(req.key,false);
    let keys = !(getMaybeValue(req.keys,false)===false);
    let anyKeys = keys || key;
    let options= {
      include_docs : getMaybeValue(req.include_docs,false)
      , conflicts : getMaybeValue(req.conflicts,false)
      , attachments : getMaybeValue(req.attachments,false)
      , descending : getMaybeValue(req.descending,false)
    };
    if (getMaybeValue(req.skip,false)) {
      options.skip=getMaybeValue(req.skip,false);
    }
    if (!anyKeys) {
      let startkey=getMaybeValue(req.startkey,false);
      let endkey=getMaybeValue(req.endkey,false);
      if (startkey) {
        options.startkey = startkey;
      }
      if (endkey) {
        options.endkey = endkey;
      }
      options.inclusive_end = getMaybeValue(req.inclusive_end,false);
      options.limit = getMaybeValue(req.limit,false);
    }
    if (key) {
      options.key = getMaybeValue(req.key,undefined);
    } else if (keys) {
      options.keys = toArray(req.keys._0);
    }
    console.log(options);
    return nativeBinding(function(callback){
      db.allDocs(options,function(err, docs) {
        if (err) { return callback(fail(toFail(err))); }
        return callback(succeed(toSuccessAllDocs(docs)));
      });
    });
  }

  function getStale(stale){
    if ( stale.ctor === 'Just') {
      switch (stale.ctor) {
      case 'Ok': 
        return 'ok';
      case 'UpdateAfter': 
        return 'update_after';
      }
    }
    return false;
  }
  
  function getReduce(reduce){
    switch (reduce.ctor) {
    case 'Sum': 
      return '_sum';
    case 'Counts': 
      return '_counts';
    case 'Stats': 
      return '_stats';
    }
    return false;
  }

  function getFun(fun){
    let returnValue;
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
  
  function query(db,opt) {
    let fun = getFun(opt.fun);
    let key = getMaybeValue(opt.key,false);
    let keys = !(getMaybeValue(opt.keys,false)===false);
    let anyKeys = keys || key;
    let options= {
      include_docs : getMaybeValue(opt.include_docs,false)
      , conflicts : getMaybeValue(opt.conflicts,false)
      , attachments : getMaybeValue(opt.attachments,false)
      , descending : getMaybeValue(opt.descending,false)
      
    };
    
    if (getMaybeValue(opt.skip,false)) {
      options.skip=getMaybeValue(opt.skip,false);
    }
    let stale = getStale(opt.stale);
    if (stale) {
      options.stale = stale;
    }
    let reduce = getReduce(opt.reduce);
    if (reduce) {
      options.reduce = reduce;
    }
    if (getMaybeValue(opt.groupLevel,false)){
      options.group = true;
      options.group_level = getMaybeValue(opt.groupLevel,false);
    }
    if (!anyKeys) {
      let startkey=getMaybeValue(opt.startkey,false);
      let endkey=getMaybeValue(opt.endkey,false);
      if (startkey) {
        options.startkey = startkey;
      }
      if (endkey) {
        options.endkey = endkey;
      }
      options.inclusive_end = getMaybeValue(opt.inclusive_end,false);
      options.limit = getMaybeValue(opt.limit,false);
    }
    if (key) {
      options.key = key;
    } else if (keys) {
      options.keys = toArray(opt.keys._0);
    }
    console.log(options);
    return nativeBinding(function(callback){
      db.query(fun,options,function(err, docs) {
        if (err) { return callback(fail(toFail(err))); }
        return callback(succeed(toSuccessQuery(docs)));
      });
    });
  }
  
  return { db: F2(db)
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
