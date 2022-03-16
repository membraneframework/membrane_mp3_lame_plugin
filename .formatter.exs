[
  inputs: [
    "{lib,spec,test,c_src,config}/**/*.{ex,exs}",
    "*.exs"
  ],
  import_deps: [:membrane_core, :bundlex, :unifex]
]
