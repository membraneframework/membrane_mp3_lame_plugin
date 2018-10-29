[
  inputs: [
    "{lib,spec,c_src,config}/**/*.{ex,exs}",
    "*.exs"
  ],
  import_deps: [:membrane_core, :espec, :bundlex, :unifex]
]
