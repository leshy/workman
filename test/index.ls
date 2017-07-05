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

describe 'root', ->

  specify 'init', -> new p (resolve,reject) ~>
    env = do
      settings:
        module:
          mongo:
            name: 'test'
    
    init env, (err,env) ->
      
      TaskSync =  Task.extend4000({})
      
      TaskCollection = Backbone.Collection.extend4000 do
        name: 'task'
        model: TaskSync

      TaskCollection::sync = TaskSync::sync = env.mongo.sync TaskCollection

      collection = new TaskCollection()
      x = new TaskSync test: 33, args: { bla: 1 }
      x.save()
      .then ->
        console.log x.attributes
        x.set test: 66
        x.save()
        .then ->
          x.fetch()
          .then ->
           console.log "MODEL READ",it
           collection.fetch()
           .then ->
              x.destroy()
              .then ->
                console.log "destroy", it

                resolve!
      

      

    
  # specify 'store', -> new p (resolve,reject) ~>
  #   x = new Task test: 33, args: { bla: 1 }
  #   x.save (err,data) ->
  #     console.log "SAVE", err,data
  #   # x.save do
  #   #   error:  (data) -> console.log "SAVE", err,data
  #   #   success:  (data) -> console.log "SAVE", err,data
