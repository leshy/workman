require! {
  colors
  bluebird: p
  introspect
  leshdash: { isEqual, clone, keys, values, identity, find, lazy, union, assign, omit, map, mapValues, curry, times, first, wait, each, identity, cremove, jsonQuery, head, reduce }
  leshdash: _
  backbone4000: Backbone
  autoIndex
  util
  path
  'pretty-hrtime'
  abstractman: { DirectedGraphNode, GraphNode }
#  'backbone-mongo'
}

#
# Runtime is instantiated when Task waterline model wants to execute itself
# deals with queueing, task state recovery, saving to db, etc
# this code is not in Task model in order to avoid poluting the store with runtime variables
#
# omg check this - if a task writes to transient data, its implicitly marked as a transient task?
# 
# figure out how to get task execution progress info, not just a promise <3
# 
  
export Task = Backbone.Model.extend4000 do
  initialize: ->
    console.log 'task init'
  # urlRoot: 'mongodb://localhost:27017/task/task'
  # schema:
  #   state: [ indexed: true ]
      
export Taskx = Backbone.Model.extend4000 do
#  initialize: (cb) ->
#    cb!
#    @awakeTasks!
#    setInterval (~> @checkSchedule!), 30000

  awakeTasks: ->
    @log "task scheduler running"

    p.props do
      run: @store.find({ state: 'run'})
      wait: @store.find({ state: 'wait', start: { '<=': new Date() } })
      waitLater: @store.find({ state: 'wait', start: { '>': new Date() } })

    .then ({ run, wait, waitLater }) ~> 
      @log "task scheduler found #{run.length} tasks to re-run, #{wait.length} that should be run now and #{waitLater.length} to run at a later time"
      if run.length then each run, (.exec!)
      if wait.length then each wait, (.exec!)

  exec: (name, args={}) ->
    @store.create name: name, args: args
    .then (task) -> task.exec()

  schedule: (time, name, args={}) ->
    @store.create name: name, args: args, start: time, state: 'wait'
    .then -> true

  checkSchedule: ->
    @store.find({ state: 'wait', start: { '<=': new Date() } })
    .then (tasks) -> each tasks, (.exec!)

export Runtime = GraphNode.extend4000 do
  plugs:
    tasks: { singular: 'task' }

  initialize: ({ store }) ->
    @store = store    
    @args = store.args or {}
    
    @logger = @logger.child { tags: { task: store.id, module: "task" } }
    @log = @logger~log

  state: (state, endTime) ->
    @store.state = state
    @save()
    .then ~> new p (resolve,reject) ~>
      if not endTime? then @log "task #{@store.name} changed state to #{state}", {}, { name: @store.name, state: state }
      else @log "task #{@store.name} changed state to #{state} after #{prettyHrtime endTime}", { time: endTime }, { name: @store.name, state: state }
      resolve!
  
  exec: -> new p (resolve,reject) ~> 
    startTime = process.hrtime()
    endTime = -> process.hrtime startTime

    @state 'run'
    .then ~>
      @execTask @store.name

      .then ~>
        @state 'ok', endTime()
        resolve it

      .catch ~>
        @store.error = do
          name: String it
          stack: it.stack
          
        @state 'error', endTime()
        reject it

  execTask: (fullName, args={}, logger) ->
    # check if a task with this name and args is already in our context
    if task = @existingTask(fullName, args) then return task.exec()
      
    opts = do
      runtime: @
      logger: (logger or @logger)
      args: (args)

    cls = jsonQuery fullName, tasks, '/'
    if cls?@@ isnt Function then return new p (resolve,reject) ~> reject new Error "Task named #{ fullName } not found"
      
    task = new cls opts
    
    @tasks.add task
    task.exec()
  
  # find task instance by name & arguments (used by subtasks to find dependencies that are already instantiated)
  existingTask: (fullName, args) ->
    
    @tasks.find (task) ->
      if task.fullName isnt fullName then return false
      if args then return isEqual task.get('args'), args
      else return true

  save: ->
    if @store.state isnt 'ok'
      @store.data = do
        tasks: @tasks.map (.serialize!) |> cremove identity
        permanent: @permanent
    else
      # we don't need the data if task finished
      @store.data = {}
      
    @store.save()

TaskDef = DirectedGraphNode.extend4000 do

  # inheritance customization (see backbone4000 - or don't, its complicated)
  # this will merge a retry dictionary that a subclass might define into this current default retry dictionary
  
  mergers: [ Backbone.metaMerger.mergeDict('retry') ]
  
  initialize: ({ @runtime, logger }) ->
    @logger = logger.child()
    @log = @logger~log
  
  args: -> {} <<< @runtime.args <<< @get 'args'

  serialize: ->
    do
      name: @fullName
      args: @get 'args'
      value: if (@transient or not @_promise?isFufilled) then false else @_promise?value()

  execDeps: ->
    args = introspect @_
    
    ignore = { +'args', +'arg$' }
    
    if not args.length or (args.length is 1 and ignore[head args]?)
      @log "exec #{@fullName}", {}, { state: 'exec', name: @fullName }
      @_ @args()
    else
      @log "preexec #{@fullName} (depends on #{args.join(',')})", {}, { state: 'preexec', name: @fullName }

      @tasks reduce do
        args,
        (obj, value) -> if value is 'args' then obj else obj <<< { "#{value}": true }
        {}
        
      .then (childResponses) ~>
        args := map args, -> childResponses[it]
        @log "exec #{@fullName}", {}, { state: 'exec', name: @fullName }
        @_.apply @, [ ...args, @args! ]
        
  exec: ->
    if @_promise then return @_promise

    startTime = process.hrtime()
    endTime = -> process.hrtime startTime
    
    @_promise = @execDeps()
    
    .then ~>
      t = endTime()
      @log "done #{@fullName} #{prettyHrtime t}", {t: t}, { state: 'ok', name: @fullName }
      return it
      
    .catch ~>
      t = endTime()
      @log "error #{@fullName} #{prettyHrtime t} #{it}", {t: t, stack: JSON.stringify(it.stack) }, { state: 'error', name: @fullName }
      throw it

  tasks: (tasks) ->
    p.props mapValues tasks, (args, name) ~>
      if args === true then args = void
      @task name, args

  find: (targetName) -> new p (resolve,reject) ~>
    found = -> resolve it
    notFound = ~> reject new Error "task named '#{targetName}' not found in the context of '#{@folder}'"
    
    # we got an absolute path
    if targetName.indexOf("/") isnt -1
      return if not jsonQuery(targetName, tasks, '/') then notFound() else found(targetName)

    tryPath = (...paths) ->
      fullName = path.join.apply path, paths
      if jsonQuery(fullName, tasks, '/')?@@ is Function then return found fullName
      else return false

    # search through your folder and parent folders
    climbDown = (folder) ->
      if promise = (tryPath(folder.join('/'), targetName) or tryPath(folder.join('/'), 'index/', targetName))
        return promise
      else
        if not folder.length then return notFound()
        [ ...folder, toGarbage ] = folder
        return climbDown folder

    climbDown @folder

  task: (targetName, args) ->
    @find targetName
    .then ~> @runtime.execTask it, args, @logger

  fork: (targetName, args) ->
    @find targetName
    .then ~> sails.hooks.taskscheduler.exec it, @args() <<< args

  thread: (targetName, args) ->
    @find targetName
    .then ~> sails.hooks.taskscheduler.exec it, args

  schedule: (time, targetName, args) -> 
    @find targetName
    .then ~> sails.hooks.taskscheduler.schedule time, targetName, args

export init = (dir) -> 
  # This goes through folders recursively and require everything inside, building a dictionary
  # check: https://github.com/leshy/autoIndex

  new WorkMan do
    tasks: autoIndex do
      dir, {},
      # some preprocessing on task definitions, adding fullname & name and extending original taskDef model
      (data, folder) ->
        mapValues data, (val, key) ->
          switch val@@
            | Object =>
              TaskDef.extend4000 val <<< do
                name: key
                folder: folder
                fullName: path.join folder.join('/'), key

            | otherwise => val

