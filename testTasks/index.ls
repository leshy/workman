require! {
  leshdash: { wait }
  bluebird: p
}

export
  success: do
    _: (args) -> new p (resolve,reject) ~> 
      wait 100, -> resolve args
      
  fail: do
    _: (args) -> new p (resolve,reject) ~> 
      wait 100, -> reject args
