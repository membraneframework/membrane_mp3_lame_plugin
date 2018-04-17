use Mix.Config

config :membrane_element_lame, :bundlex_lib,
  macosx: [
    nif: [
      membrane_element_lame_encoder: [
        includes: [
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "../../membrane_common_c/c_src/membrane/log.c",
          "encoder.c",
        ],
        libs: [
        ],
        pkg_configs: [
          "lame"
        ]
      ]
    ]
  ],
  windows32: [
    nif: [
      membrane_element_lame_encoder: [
        includes: [
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
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
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "encoder.c",
        ],
        libs: [
        ],
        pkg_configs: [
          "lame"
        ]
      ]
    ]
  ],
  linux: [
    nif: [
      membrane_element_lame_encoder: [
        includes: [
          "../membrane_common_c/c_src/",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "../../membrane_common_c/c_src/membrane/log.c",
          "encoder.c",
        ],
        libs: [
        ],
        pkg_configs: [
          "lame"
        ]
      ]
    ]
  ]
