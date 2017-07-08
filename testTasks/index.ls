require! {
  leshdash: { wait }
  bluebird: p
  assert
}

export
  success: do
    _: (args) -> new p (resolve,reject) ~> 
      wait args.time, -> resolve args
      
  success2: do
    _: (args) -> new p (resolve,reject) ~> 
      wait args.time, -> resolve args
      
  fail: do
    _: (args) -> new p (resolve,reject) ~> 
      wait args.time, -> reject args

  dep: do
    _: (args) -> new p (resolve,reject) ~>
      @task 'success', { test: 3 }
      .then ->
        assert.equal it.test, 3
        resolve dep: true

  depImplicit: do
    _: (dep) -> new p (resolve,reject) ~>
      assert.equal dep.dep, true
      resolve!

  depMulti: do
    _: (args) -> new p (resolve,reject) ~>
      @tasks do
        success: { time: 10 }
        success2: { time: 20 }
      .then ( { success, success2 }) ->
        assert.equal success.time, 10
        assert.equal success2.time, 20
      
        resolve depMulti: true


