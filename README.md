Rewire is a Roblox library that makes adding HotReload functionality easy.

**What's Hot Reloading?**
Hot Reloading means changing the behavior of your game immediately when some code is edited. This means you can write code *while your game is running in studio play mode* and see updates happen in realtime, without having to stop and start the running session. 

Here is an example of HotReloading used to edit Roact UI while the game is running:
https://user-images.githubusercontent.com/6133296/161100007-9e6616f1-01ca-4d1d-9812-270fbc238433.mp4


**How to use it?**
1) Create a new HotReloader object:
```lua
local Rewire = require(WHEREVER_REWIRE_IS)
local reloader = Rewire.HotReloader.new()
```
2) Listen to a modulescript for which you want to support HotReloading
```lua

local requiredModule = nil

reloader:listen(WHICHEVER_MODULE, function(module:ModuleScript)
   -- callback invoked immediately upon listening, and whenever the module in question updates
   -- this could include requiring the module and changing a global reference
   requiredModule = require(module)
end,
function(module:ModuleScript)
   -- do whatever needs to be done on cleanup
   -- this could be destroying objects that need to be destroyed, or unmounting a Roact handle
end)
```
