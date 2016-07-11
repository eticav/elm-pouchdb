'use strict';

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
    return raw;
  };
  
  function toComplete(raw){
    
    return { ctor: 'Completed'};
  };

  function toSince(since){
    if ( since.ctor === 'Seq') {return since._0;}
    return false;
  }
 
  
  function toOptions(options)
  {
    return   {
      live : options.live
      , include_docs : options.include_docs
      , include_conflicts : options.include_conflicts
      , attachments : options.attachments
      , descending  : options.descending
      , since : toSince(options.since)
      , limit : getMaybeValue(options.limit,false)} ;
  };
  
  function changes(db,options,toChangeTask)
  {
    //console.log(options);
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
