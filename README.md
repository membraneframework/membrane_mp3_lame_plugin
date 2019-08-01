# Membrane.Element.Lame

[![CircleCI](https://circleci.com/gh/membraneframework/membrane-element-lame.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane-element-lame)


Module containing element that encodes raw audio to MPEG-1 layer 3 format.

For now, only encoding audio with 2 channels, s32le format and 44100 sample rate is supported.

It is part of [Membrane Multimedia Framework](https://membraneframework.org).

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
{:membrane_element_lame, "~> 0.3"}
```

[Lame encoder library](http://lame.sourceforge.net) is required to use this element.

### Compilation on Unix systems

To compile NIF you have to make sure `ext/lame.pc` is visible to the pkg-config.
That can be achieved by adding `ext` directory path to the environment variable `PKG_CONFIG_PATH`
or by copying `ext/lame.pc` to the pkg-config dir (i.e. `/usr/lib/pkgconfig`)

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://membraneframework.github.io/static/logo/swm_logo_readme.png)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
