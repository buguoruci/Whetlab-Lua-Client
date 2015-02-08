Whetlab-Lua-Client
==================

Installing the Lua Client
-------------------------

The easiest way to install is using [luarocks](http://luarocks.org/).  Just type:

    luarocks install whetlab
    
and you're done!  

However, if you need to install from source:

First download the Lua Client either as a zip archive [here](https://github.com/whetlab/Whetlab-Lua-Client/archive/master.zip) or clone it using Git

    git clone https://github.com/whetlab/Whetlab-Lua-Client

You will need to download the Lua dependencies for the client using [luarocks](http://luarocks.org/).  You can do this by typing

    luarocks install luasec  
    luarocks install luasocket  
    luarocks install luajson  

Now you just have to add whetlab to your LUA_PATH:

    export LUA_PATH="$LUA_PATH;<path-to-the-client>/Whetlab-Lua-Client/?.lua"
    
Getting Started
---------------

Check out our Lua client [API Reference](https://www.whetlab.com/docs/lua-api-reference/) for details on how to use the client or take a look at the [examples](https://github.com/whetlab/Whetlab-Lua-Client/tree/master/examples) subdirectory for example usage.
