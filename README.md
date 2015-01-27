#DEPRECATED
**DO NOT USE**

Take a look at `polymer-serve` instead.  Polymer-tools is not being maintained.

https://github.com/Custom-Elements/polymer-serve

#polymer-build

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

##Options

###nobrowserify

Use the attribute `nobrowserify` on link import and scripts to get the raw javascript, no browserify. This is
transitive, or really scoped, if you apply it to a link import, it counts for all the script tags inside. 

TLDR: use this on elements you get from the Polymer Core team.

###skip-vulcanization

Use the attribute `skip-vulcanization` on imports to not vulcanize them.
