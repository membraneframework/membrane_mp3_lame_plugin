use Mix.Config

config :membrane_element_lame, :bundlex_lib,
  macosx: [
    nif: [
      membrane_element_lame_encoder: [
        includes: [
          "../membrane_common_c/include",
          "./deps/membrane_common_c/include",
        ],
        sources: [
          "encoder.c",
        ],
        libs: [
        ]
      ]
    ]
  ],
  windows32: [
    nif: [
      membrane_element_lame_encoder: [
        includes: [
          "../membrane_common_c/include",
          "./deps/membrane_common_c/include",
        ],
        sources: [
          "encoder.c",
        ],
        libs: [
        ]
      ]
    ]
  ],
  windows64: [
    nif: [
      membrane_element_lame_encoder: [
        includes: [
          "../membrane_common_c/include",
          "./deps/membrane_common_c/include",
        ],
        sources: [
          "encoder.c",
        ],
        libs: [
        ]
      ]
    ]
  ],
  linux: [
    nif: [
      membrane_element_lame_encoder: [
        includes: [
          "../membrane_common_c/include",
          "./deps/membrane_common_c/c_src",
          "/usr/lib/erlang/erts-8.3/include/"
        ],
        sources: [
          "encoder.c",
        ],
        libs: [
          "mp3lame"
        ]
      ]
    ]
  ]