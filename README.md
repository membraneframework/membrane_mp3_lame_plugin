# Membrane Element: Lame Encoder

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_element_lame.svg)](https://hex.pm/packages/membrane_element_lame)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_element_lame/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane-element-lame.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane-element-lame)

Module containing element that encodes raw audio to MPEG-1 layer 3 format.

For now, only encoding audio with 2 channels, s32le format and 44100 sample rate is supported.

It is part of [Membrane Multimedia Framework](https://membraneframework.org).

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
{:membrane_element_lame, "~> 0.4.0"}
```

[Lame encoder library](http://lame.sourceforge.net) is required to use this element.
You can install it using the following commands:

### MacOS

```bash
brew install lame
```

### Ubuntu

```bash
sudo apt-get install libmp3lame-dev
```

### Arch, Manjaro

```bash
sudo pacman -S lame
```

### Fedora

```bash
sudo dnf install lame-devel
```

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-element-lame)

[![Software Mansion](https://membraneframework.github.io/static/logo/swm_logo_readme.png)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-element-lame)

Licensed under the [Apache License, Version 2.0](LICENSE)
