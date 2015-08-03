# HyperJump for fish

This is a port of [Bogdan's HyperJump](http://sdbr.net/post/HyperJump/)
for [fish](https://github.com/fish-shell/fish-shell).

It does not include the graphical menu as fish's built-in autocomplete
facilities are far more advanced than most other shells.

# Usage

`jr` will remember a location and can be used as follows

```fish
jr  $name           # Remember $PWD as $name
jr  $name $path     # Remember $path as $name
```

`jf` will forget a location 

```fish
jf          # Forget the location associated with $PWD, if any
jf  $path   # Forget the location associated with $path
jf  $name   # Forget the location stored as $name
```

_Note:_ `jf` will check for paths before checking for nicknames. It will
not check for nicknames if you do not specify a `$path` or `$nickname`.
This it done to prevent potention issues.

`jj $name` will use `cd` to go to a location
`jp $name` will use `pushd` to go to a location

`jl` will output a table of locations
