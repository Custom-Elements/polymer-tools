```
Usage:
  polymer-build [options] watch <root_directory> <source_directory> <build_directory> [<only_these>...]
  polymer-build [options] <source_directory> <build_directory> [<only_these>...]


  --help             Show the help
  --exclude-polymer  When building kits with polymer elements from the core
                     team, skip importing polymer itself to avoid dual init
  --copy-polymer     When going to the <build_directory> copy over polymer
                     itself to the destination. Useful for whole apps.
  --filewatch        Watch for file changes and rebuild, not just on pull.
  --compress         Make the output smaller by removing comments and source maps.
  --quiet            SSSHHH! Less logging.
```
