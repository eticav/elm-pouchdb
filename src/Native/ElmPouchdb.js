var _user$project$Native_ElmPouchdb = function() {
  
  var nativeBinding = _elm_lang$core$Native_Scheduler.nativeBinding;
  var succeed = _elm_lang$core$Native_Scheduler.succeed;
  var fail = _elm_lang$core$Native_Scheduler.fail;
  var Nothing = _elm_lang$core$Maybe$Nothing;
  var Just = _elm_lang$core$Maybe$Just;
  var EmptyList = _elm_lang$core$Native_List.Nil;
  var Cons = _elm_lang$core$Native_List.Cons; 
  var rawSpawn = _elm_lang$core$Native_Scheduler.rawSpawn;

  
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
      message: error.message
    };
  }
  
  function toSuccessPut(response){
    return { id: response.id
             , rev: response.rev
           };
  }
  
  function db(name)
  {
    return new PouchDB(name);
  };


  function toRevsGet(revisons){
    var revs = EmptyList;
    for (var property in revisons.ids) {
      var rev = {};
      console.log(revisons.start-property);
      rev.sequence= revisons.start-property;
      rev.uuid = revisons.ids[property];
      revs = Cons(rev, revs);
    }
    return revs;
  }

  function toSuccessGet(response) {
    var val = {};
    val['response'] = {};
    val['conflicts'] = Nothing;
    val['revisions'] = Nothing;
    for (var property in response) {
      if (property === "_conflicts") {
        val['conflicts'] = Just(response[property]);
      } else if (property === "_revisions") {
        val['revisions'] = Just(toRevsGet(response[property]));
      } else
        val['response'][property] = response[property];
    }
    return val;  
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

  function get(db,req) {
    var id = req.id;
    var options= { rev: getMaybeValue(req.rev,false)
                   , revs: getMaybeValue(req.revs,false)
                   , attachments : getMaybeValue(req.attachments,false)
                   , binary: getMaybeValue(req.binary,false)
                 };
    return nativeBinding(function(callback){
      db.get(id, options,function(err, doc) {
        if (err) { return callback(fail(toFail(err))); }
        return callback(succeed(toSuccessGet(doc)));
      });
    });
  }
  
  function toChange(rawchange){
    return rawchange;
  };
  
  function toError(rawError){
    return rawError;
  };
  
  function toComplete(rawComplete){
    return rawComplete;
  };
  
  function changes(db,options,toChangeTask,toCompleteTask,toErrorTask) {
    var opt= { since: 'now'
               , live: true
               , include_docs: true
             };
    
    return nativeBinding(function(callback){
      
      function onChange(rawchange)
      {
        var change = toChange(rawchange);
	var task = toChangeTask(change);
	rawSpawn(task);
      }
      
      function onError(rawError)
      {
	var error = toError(rawError);
	var task = toErrorTask(error);
	rawSpawn(task);
      }

      function onComplete(rawComplete)
      {
	var error = toComplete(rawComplete);
	var task = toCompleteTask(error);
	rawSpawn(task);
      }
      
      var changes = db.changes(options)
            .on('change', onChange)
            .on('complete', onComplete)
            .on('error', onError);
      
      return function() {
        changes.cancel();
      };
    });
  };
  
  return { db: db
           , destroy: destroy
           , get: F2(get)
           , put: F3(put)
           , post: F2(post)
           , remove:F3(remove)
           , removeById: F3(remove)
           , changes: F5(changes)
         };
  
}();
