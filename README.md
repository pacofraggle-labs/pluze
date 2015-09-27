
## What is PLUZE about?

PLUZE is both a launcher for existing toolkits - library functions (stored in script files that can be sourced) - and a documentation manager for those function libraries.

In a way it is a very rudimentary Bash implementation of the import/require library mechanisms of languages such as Java or Ruby and a command-line utility to write JavaDoc-like help.

I would find it hard to believe that there are not other more powerful tools like this one for shell programming.
However I've never come across any of them and it was simpler for me to implement this basic tool.

For me, this all started when I got tired of writing `git push origin master` (I prefer `g pom`)  and other git related functions.
I know that I can use aliases but then I noticed that I was also constantly repeating myself and forgetting about the syntax when I needed to use ffmpeg, when I had to work with production servers, rename files, and so on.
I had the feeling that I was repeating myself too much and the refactoring led to PLUZE.


The only file in this project you need to use pluze is *pluze\_bootstrap*. The rest of them are my personal libraries and scripts.
I've added them to the project to keep a control version of them and to use them as examples. In any case, if you find any of them useful for you, please do not hesitate to use them!

### How does it work?

You just need to set up several environment variables (the _toolkits_ and _bootstrap_ dirs) and then load *pluze\_bootstrap*.

Accepted environment variables:
* `PLUZE_DRYRUN`:         Set dryrun on. Please notice that the dryrun behaviour has to be implemented in the method you are calling. The debug mode can be better enabled passing the *--dryrun* parameter
* `PLUZE_VERBOSE`:        Show verbose information if set to 1
* `PLUZE_TOOLKITS_DIR`:  Where to find the toolkits
* `PLUZE_BOOTSTRAP_DIR`: Where to find the bootstrap script

When you bootstrap PLUZE, 4 very simple methods will be available:

1. `pluze_load()`: sources a toolkit file
2. `pluze_help()`: finds help for a toolkit or all loaded toolkits
3. `pluze_method_help()`: finds help for a toolkit method
4. `pluze_run()`: executes a toolkit method

Using my tool helpers for ssh common operations (assuming that the public key is used to prevent passing the password manually) as an example, the basic usage of PLUZE goes like this. You have an executable file called `prod`:

    #!/bin/bash

    . "$PLUZE_BOOTSTRAP_DIR/pluze_bootstrap" <= bootstrap pluze

    pluze_load "ssh_server"                  <= load the "ssh_server" toolkit functions. 
                                                You can load as many toolkits as you need at any time

    pluze_run "$@"                           <= execute the function in $1 passing the 
                                                rest of arguments as function parameters

`ssh_server` is a toolkit file with functions that you will make available for use once you load it (using *pluze\_load*).
Toolkits are loaded from the following folders in a failback mode using this order:

1. `PLUZE_TOOLKITS_DIR`
2. `<bootstrap_dir>/pluze_toolkits`
3. `~/bin/pluze_toolkits`
4. `./pluze_toolkits`

You can play with these folders as you need. You could decide to have a central toolkits dir and custom dirs for other projects.
You can also use nested directories inside the toolkits dir (for instance, you could have separate toolkits for _git_ such as _git/basic_ or _git/advanced_).

In the presence of name collisions in function names for different toolkits, the first implementation found using the load order hides any other ones. You can use this behaviour to implement an overriding mechanism.

Toolkits are assumed to be independent and contain methods that you want to call from other scripts. Please notice that any code outside of a function in a toolkit will be executed during the load time. This is a piece of the `ssh_server` toolkit:

    #!/bin/bash

    => It is unlikely that you need any startup code but in this case we need to 
    => ensure that there are variables that define the server name and the user
    if [ -z $PROD_SERVER ]; then
      echo "ERROR: PROD_SERVER variable not set"
      exit 255
    fi

    if [ -z $PROD_SERVER_USER ]; then
      PROD_SERVER_USER=`who am i | cut -d " " -f 1`
    fi

    if [ -z $PROD_SERVER_PORT ]; then
      PROD_SERVER_PORT=22
    fi

    => This is the general documentation for the ssh_server toolkit

    ##DOC: Common server communications that assume public key sharing
    ##DOC:

    => Here you will have method definitions. Each of them can be preceeded 
    => by ##DOC comments if you want to use PLUZE for help management

    ##DOC: up <files>+: scp to server    <= Method description
    ##DOC:   <files>: Files to copy      <= Parameters description
    function up() {

      if [ $# -eq 0 ]; then
      echo "WARNING: nothing to copy"
      return 255
    fi

    echo "scp -r -P $PROD_SERVER_PORT $* $PROD_SERVER_USER@$PROD_SERVER:"
    if [ $PLUZE_DRYRUN -eq 0 ]; then
      scp -r -P $PROD_SERVER_PORT $* ${PROD_SERVER_USER}@${PROD_SERVER}:
    fi
  }

You will notice that there are only two dependencies with PLUZE here:

* `PLUZE_DRYRUN`: This is the way to know that a dryrun execution has been requested
* `return 255`:    If the method returns 255, PLUZE will finish the method execution showing its help

If you document your toolkits with `##DOC` comments, PLUZE  will provide you with help info using the _-h_ or the _--help_ parameter:

    $ prod -h  # or prod --help

    Common server communications that assume public key sharing

    up <files>+: scp to server
      <files>: Files to copy
    ...

      --help, -h  show this help
      --dryrun    can precede any of the script commands
                  (however it is not guaranteed that they can be debugged)

and this:

    $ prod up --help  # or prod up -h

    up <files>+: scp to server
      <files>: Files to copy

If no method is passed then the help for all loaded toolkits will be shown.
On the other hand, if a method is passed, the help for that method will be shown.

### Misc. details

You do not need to use them explicitly but you should be aware that `pluze_load` uses the following global arrays:

* `pluze_toolkits`:  List of loaded toolkits (so that they are not loaded more than once)
* `pluze_functions`: Available loaded functions. Only these methods can be executed using PLUZE.

If any of the functions in a toolkit are not meant to be usable by scripts you need to mark them with the `# Internal` comment like this:

    function f() { # Internal
