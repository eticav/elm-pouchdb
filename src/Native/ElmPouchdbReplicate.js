'use strict';

//var _powet$elm_pouchdb$Native_ElmPouchdbReplicate = function() {
var _user$project$Native_ElmPouchdbReplicate = function() {
  
  var nativeBinding = _elm_lang$core$Native_Scheduler.nativeBinding;
  var succeed = _elm_lang$core$Native_Scheduler.succeed;
  var fail = _elm_lang$core$Native_Scheduler.fail;
  var Nothing = _elm_lang$core$Maybe$Nothing;
  var Just = _elm_lang$core$Maybe$Just;
  var EmptyList = _elm_lang$core$Native_List.Nil;
  var Cons = _elm_lang$core$Native_List.Cons; 
  var rawSpawn = _elm_lang$core$Native_Scheduler.rawSpawn;
  var toArray = _elm_lang$core$Native_List.toArray;
  
  function toChange(raw){
    return { ctor: 'Changed'};
  };
  
  function toError(raw){
    return { ctor: 'Error'};
  };

  function toPaused(raw){
   return { ctor: 'Paused'};
  };

  function toActive(raw){
    return { ctor: 'Active'};
  };

  function toDenied(raw){
    return { ctor: 'Denied'};
    };
  
  function toComplete(raw){
    
    return { ctor: 'Completed'};
  };

  function toSince(since){
    if ( since.ctor === 'Seq') {return since._0;}
    if ( since.ctor === 'Now') {return 'now';}
    return false;
  }
  
  function toLive(live){
    return !(live.ctor === 'Nothing');
  }
  
  function setRetry(live,options){
    if ( toLive(options.live) && live.ctor === 'Retry' ) {
      options.retry =true;
    }
    return options;
  }
    
  function setBackOff(live,options){
    if (live.ctor === 'Retry' && live._0.ctor === 'Just' ) {
      options.backOff=live._0._0;
    };
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
  
  function setMaybe(attr,doc_ids,options){
    if ( doc_ids.ctor === 'Just' ) {
      options[attr] = doc_ids._0;
    }
    return options;
  }
  
  function toOptions(options)
  {
    var live = toLive(options.live);
    var returnOpt= { live : live
                     , since : toSince(options.since)
                   };
    
    if (live) {
      setRetry(options.live, returnOpt);
      setBackOff(options.live, returnOpt);
    }
    
    setFilter(options.filter,returnOpt);
    
    // setMaybe('query_params',options.query_params,returnOpt); //TODO
    setMaybe('heartbeat',options.heartbeat,returnOpt);
    setMaybe('timeout',options.timeout,returnOpt);
    setMaybe('batch_size',options.batch_size,returnOpt);
    setMaybe('batches_limit',options.batches_limit,returnOpt);
  
    return returnOpt;
  };
    
  function replicate(source,target,options,toTask)
  {
    //console.log(options);
    return nativeBinding(function(callback){
      
      function onChange(raw)
      {
        var obj = toChange(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };

      function onPaused(raw)
      {
        var obj = toPaused(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };
      
      function onActive(raw)
      {
        var obj = toActive(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };

      function onDenied(raw)
      {
        var obj = toDenied(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };
      
      function onComplete(raw)
      {
	var obj = toComplete(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };

      function onError(raw)
      {
	var obj = toError(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };
      
      var replicate = source.replicate.to(target,toOptions(options))
            .on('change', onChange)
            .on('paused', onPaused)
            .on('active', onActive)
            .on('denied', onDenied)
            .on('complete', onComplete)
            .on('error', onError);
      
      return function()
      {
        replicate.cancel();
      };
    });
  };

  function sync(source,target,pushOptions,pullOptions,toTask)
  {
    //console.log(options);
    return nativeBinding(function(callback){
      
      function onChange(raw)
      {
        var obj = toChange(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };

      function onPaused(raw)
      {
        var obj = toPaused(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };
      
      function onActive(raw)
      {
        var obj = toActive(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };

      function onDenied(raw)
      {
        var obj = toDenied(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };
      
      function onComplete(raw)
      {
	var obj = toComplete(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };

      function onError(raw)
      {
	var obj = toError(raw);
	var task = toTask(obj);
	rawSpawn(task);
      };

      var options = { push : toOptions(pushOptions)
                      , pull : toOptions(pullOptions)
                    };
      
      var replicate = source.sync(target,options)
            .on('change', onChange)
            .on('paused', onPaused)
            .on('active', onActive)
            .on('denied', onDenied)
            .on('complete', onComplete)
            .on('error', onError);
      
      return function()
      {
        replicate.cancel();
      };
    });
  };
  
  return { replicate: F4(replicate)
           , sync : F5(sync)
         };
  
}();
