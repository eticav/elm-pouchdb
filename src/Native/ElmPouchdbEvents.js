'use strict';

var _user$project$Native_ElmPouchdbEvents = function() {
  
  var nativeBinding = _elm_lang$core$Native_Scheduler.nativeBinding;
  var rawSpawn = _elm_lang$core$Native_Scheduler.rawSpawn;

  function toCreated(raw){
    return  { ctor: 'Created'
              , _0: raw
            };
  };

   function toDestroyed(raw){
     return  { ctor: 'Destroyed'
               , _0: raw
             };
   };
  
  function listen(toTask)
  {
    //console.log(options);
    return nativeBinding(function(callback){
      
      function onCreated(raw)
      {
        let obj=toCreated(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };

      function onDestroyed(raw)
      {
        let obj=toDestroyed(raw);
	let task = toTask(obj);
	rawSpawn(task);
      };
      
      let listen = PouchDB
            .on('created', onCreated)
            .on('destroyed', onDestroyed);
      
      return function()
      {
        listen.cancel();//TODO : probably incorrect check in pouchdb documentation
        // does it make sense to unsubcribe?
      };
    });
  };
  
  return { listen: listen
         };
  
}();
