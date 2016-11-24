'use strict';

//var _powet$elm_pouchdb$Native_ElmPouchdbChange = function() {
var _user$project$Native_ElmPouchdbChange = function() {
  
  var nativeBinding = _elm_lang$core$Native_Scheduler.nativeBinding;
  var succeed = _elm_lang$core$Native_Scheduler.succeed;
  var fail = _elm_lang$core$Native_Scheduler.fail;
  var Nothing = _elm_lang$core$Maybe$Nothing;
  var Just = _elm_lang$core$Maybe$Just;
  var EmptyList = _elm_lang$core$Native_List.Nil;
  var Cons = _elm_lang$core$Native_List.Cons; 
  var rawSpawn = _elm_lang$core$Native_Scheduler.rawSpawn;
  var toArray = _elm_lang$core$Native_List.toArray;


  function getMaybeValue(val,d){
    if ( val.ctor === 'Just') {return val._0;}
    return d;
  }
  
    function toChangesRevs(raw){
    return raw[0].rev;
  };

  function toChangesDoc(raw){
    if (raw)
      return Just(raw);
    else
      return Nothing;
  };
  
  function toChange(raw){
    return  { ctor: 'Changed'
              , _0: { id: raw.id
                      , rev: Just(toChangesRevs(raw.changes))
                      , doc: toChangesDoc(raw.doc)
                      , revisions : Nothing
                      , conflicts : Nothing
                      , sequence: Just(raw.seq)
                      , key : Nothing
                    }
            };
  };
  
  function toError(raw){
    return { ctor: 'Error'
             , _0 : { status: raw.status,
                      name: raw.name,
                      message: raw.message
                    }
           };
  };
  
  function toComplete(raw){
    
    return { ctor: 'Completed'};
  };

  function toSince(since){
    if ( since.ctor === 'Seq') {return since._0;}
    if ( since.ctor === 'Now') {return 'now';}
    return false;
  }

   function setMaybe(attr,doc_ids,options){
    if ( doc_ids.ctor === 'Just' ) {
      options[attr] = doc_ids._0;
    }
    return options;
  }

  function setFilter(filter,options){
    if ( filter.ctor === 'Name' ) {
      options.filter = filter._0;
    }
    if ( filter.ctor === 'Fun' ) {
      options.filter = Function ('doc', filter._0);
    }
    if ( filter.ctor === 'View' ) {
      options.filter = '_view';
      options.view = filter._0;
    }
    if ( filter.ctor === 'Ids' ) {
       options.doc_ids=toArray(filter._0);
    }
    return options;
  }
  
  function toOptions(options)
  {
    var returnOpt=  { live : options.live
                      , since : toSince(options.since)
                    };
    
    setFilter(options.filter,returnOpt);

    setMaybe('include_docs',options.include_docs,returnOpt);
    setMaybe('include_conflicts',options.include_conflicts,returnOpt);
    setMaybe('attachments',options.attachments,returnOpt);
    setMaybe('descending',options.descending,returnOpt);
    setMaybe('timeout',options.timeout,returnOpt);
    setMaybe('limit',options.limit,returnOpt);
    setMaybe('heartbeat',options.heartbeat,returnOpt);
    setMaybe('return_docs',options.return_docs,returnOpt);
    setMaybe('batch_size',options.batch_size,returnOpt);
    //, query_params : List QueryParam //TODO
    return  returnOpt;
  };
  
  function changes(db,options,toChangeTask)
  {
    return nativeBinding(function(callback){
      
      function onChange(rawchange)
      {
        var change = toChange(rawchange);
	var task = toChangeTask(change);
	rawSpawn(task);
      };
      
      function onError(rawError)
      {
	var error = toError(rawError);
	var task = toChangeTask(error);
	rawSpawn(task);
      };

      function onComplete(rawComplete)
      {
	var error = toComplete(rawComplete);
	var task = toChangeTask(error);
	rawSpawn(task);
      };
      
      var changes = db.changes(toOptions(options))
            .on('change', onChange)
            .on('complete', onComplete)
            .on('error', onError);
      
      return function()
      {
        changes.cancel();
      };
    });
  };
  
  return { changes: F3(changes)
         };
  
}();
