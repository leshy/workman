require! {
  colors  
  assert
  mongodb: { ObjectId }
  leshdash: { each, last, head, rpad, lazy, union, assign, omit, map, curry, times, keys, first, wait, head, pwait, wait, mapValues, reverse, reduce, filter }
  bluebird: p
  '../index.ls': { Task }
  ribcage: { init }
  backbone4000: Backbone
}
require! {
  assert
  leshdash: { each, last, head, rpad, lazy, union, assign, omit, map, curry, times, keys, first, wait, head, pwait, wait, mapValues, reverse, reduce, filter }
  bluebird: p
  ribcage: { init }
}

describe 'root', ->
  before ->
    @env = {}
    
  specify 'init', -> new p (resolve,reject) ~>
    @env.settings = do
      module:
        mongo:
          name: 'test'
          
        workman:
          dir: 'testTasks'
          
    init @env, (err,env) ->
      console.log env.workman.tasks
      resolve true

