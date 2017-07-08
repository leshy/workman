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


  specify 'run non existant task', -> new p (resolve,reject) ~>
    @env.workman.exec 'index/bla', time: 10
    .then -> reject new Error "non existant task shouldn't have passed"
    .catch -> 'fail', resolve true
    
  specify 'success task', -> new p (resolve,reject) ~>
    @env.workman.exec 'index/success', time: 10
    .then -> resolve true
    .catch -> reject new Error "err executing"

  specify 'fail task', -> new p (resolve,reject) ~>
    @env.workman.exec 'index/fail', time: 10
    .then -> reject new Error "fail task shouldn't have passed"
    .catch -> resolve true
    
  specify 'single dep task', -> new p (resolve,reject) ~>
    @env.workman.exec 'index/dep', {}
    .then -> resolve true
    .catch -> reject new Error "err executing"
    
  specify 'implicit dep task', -> new p (resolve,reject) ~>
    @env.workman.exec 'index/depImplicit', {}
    .then -> resolve true
    .catch -> reject new Error "err executing"

  specify 'dep multi task', -> new p (resolve,reject) ~>
    @env.workman.exec 'index/depMulti', {}
    .then -> resolve true
    .catch -> reject new Error "err executing"
