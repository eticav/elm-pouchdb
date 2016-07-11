'use strict';

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
    return raw;
  };
  
  function toError(raw){
    return raw;
  };

  function toPaused(raw){
    return raw;
  };

  function toActive(raw){
    return raw;
  };

  function toDenied(raw){
    return raw;
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

  function setView(filter,options){
    if ( filter.ctor === 'View' ) {
      options.filter = '_view';
      options.view = filter._0;
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
      options.filter=filter.live._0;
    }
    return options;
  }

  function setMaybe(attr,doc_ids,options){
    if ( doc_ids.ctor === 'Just' ) {
      options[attr] = doc_ids._0;
    }
    return options;
  }
  
  function setDocIds(doc_ids,options){
    if ( doc_ids.ctor === 'Just' ) {
      options.doc_ids = doc_ids._0;
    }
    return options;
  }
  
  function toOptions(options)
  {
    let live = toLive(options.live);
    let returnOpt= { live : live
                     , since : toSince(options.since)
                   };
    
    if (live) {
      setRetry(options.live, returnOpt);
      setBackOff(options.live, returnOpt);
    }
    setView(options.filter,returnOpt);
    setFilter(options.filter,returnOpt);
    
    setMaybe('docs_ids',options.doc_ids,returnOpt);
    setMaybe('query_params',options.query_params,returnOpt);
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
        let obj = toChange(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };

      function onPaused(raw)
      {
        let obj = toPaused(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };
      
      function onActive(raw)
      {
        let obj = toActive(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };

      function onDenied(raw)
      {
        let obj = toDenied(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };
      
      function onComplete(raw)
      {
	let obj = toComplete(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };

      function onError(raw)
      {
	let obj = toError(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };
      
      let replicate = source.replicate.to(target,toOptions(options))
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
        let obj = toChange(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };

      function onPaused(raw)
      {
        let obj = toPaused(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };
      
      function onActive(raw)
      {
        let obj = toActive(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };

      function onDenied(raw)
      {
        let obj = toDenied(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };
      
      function onComplete(raw)
      {
	let obj = toComplete(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };

      function onError(raw)
      {
	let obj = toError(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };

      let options = { push : toOptions(pushOptions)
                      , pull : toOptions(pullOptions)
                    };
      
      let replicate = source.sync(target,options)
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
