require! {
  leshdash: { wait }
}

export bla: (args) -> 
  wait 1000
  .then -> 
    console.log 'bla', args
