Rewire is a Roblox library that makes adding HotReload functionality easy.

**What's Hot Reloading?**
Hot Reloading means changing the behavior of your game immediately when some code is edited. This means you can write code _while your game is running in studio play mode_ and see updates happen in realtime, without having to stop and start the running session.

Here is an example of HotReloading used to edit Roact UI while the game is running:
https://user-images.githubusercontent.com/6133296/161100007-9e6616f1-01ca-4d1d-9812-270fbc238433.mp4

**How to use it?**

1. Create a new HotReloader object:

```lua
local Rewire = require(WHEREVER_REWIRE_IS)
local reloader = Rewire.HotReloader.new()
```

2. Listen to a modulescript for which you want to support HotReloading

```lua

local requiredModule = nil

reloader:listen(WHICHEVER_MODULE,
function(module:ModuleScript)
   -- callback invoked immediately upon listening, and whenever the module in question updates
   -- this could include requiring the module and changing a global reference
   requiredModule = require(module)
end,
function(module:ModuleScript)
   -- here you put cleanup code that needs to happen before the next invocation of the callback
   -- this could be destroying objects that need to be destroyed, or unmounting a Roact handle
end)

-- since the HotReloader doesn't yield on first invocation, requiredModule is guaranteed to be non-nil by this point
```

Rewire currently only listens to updates in Studio - on live servers, it just fires the callback once and returns.

**Some additional functionality**
As of version 0.3.0, Rewire now passes along a Context value to the callbacks. This allows callbacks to behave differently based on the types of reloading. The context parameter is structured as follows:

```lua
type Context = {
	originalModule: ModuleScript, -- a pointer to the original module that was listened to
	isReloading: boolean, -- is true if the callback was invoked while the module was reloading (instead of module removed or during the first call to :listen)
}
```

**How does this even work?**

Rewire [listens to changes on ModuleScripts](src/HotReloader.lua) to decide when to reload. Rewire then creates a clone of the ModuleScript in question - this is needed since Roblox currently caches ModuleScript sources while the game is running, so if we didn't clone then `require` wouldn't return the results of the changed code.
For convenience, Rewire tags all created clones [with a CollectionService tag](src/Constants.lua). This tag can be accessed as follows:

```lua
Rewire.CollectionServiceTag
```

You can use this tag in upstream code to ignore Rewire created modules (e.g. in `ChildAdded` or `ChildRemoved` events)
