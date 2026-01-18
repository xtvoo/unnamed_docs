# 📚 API Methods & Globals

## 🚀 Interaction API (`api`)
Methods for interacting with the cheat core, UI, and game mechanics.

| Method Signature | Description | Category | Usage |
| :--- | :--- | :--- | :--- |
| `api:add_connection(connection: RBXScriptConnection \` | table): RBXScriptConnection` | Utility | `Registers a connection to be cleaned up on unload. Accepts any object with a `:Disconnect()` method.` |
| `api:add_desync_callback(priority: number, callback: ()->CFrame?): nil` | Adds desync logic. Priority 1 (force) or 2. | Desync | ``api:add_desync_callback(2, function() return ... end)`` |
| `api:buy_item(item: string, ammo: bool, equipped: bool): nil` | Buys item/ammo. | Local | ``api:buy_item("[LMG", true)`` |
| `api:buy_vehicle(cframe: CFrame?): nil` | Buys/finds vehicle, optionally teleports. | Local | ``api:buy_vehicle(CFrame.new(...))`` |
| `api:can_desync(): boolean` | Checks if script can desync (not busy). | Desync | ``if api:can_desync() then ... end`` |
| `api:chat(message: string): nil` | Sends chat message. | Local | ``api:chat("hello")`` |
| `api:force_shoot(handle, part, origin, pos, vis): nil` | Forces a shot from tool. | Local | ``api:force_shoot(tool.Handle, target, ...)`` |
| `api:get_character_cache(player: Player): table?` | Optimized way to get character parts. | Cache | ``cache = api:get_character_cache(player)`` |
| `api:get_client_cframe(): CFrame` | Gets client CFrame (where you seem to be locally). | Desync | ``cf = api:get_client_cframe()`` |
| `api:get_current_vehicle(): Instance?` | Returns current vehicle. | Local | ``veh = api:get_current_vehicle()`` |
| `api:get_data_cache(player: Player): table?` | Info like Crew, Wanted, Currency. | Cache | ``cache = api:get_data_cache(player)`` |
| `api:get_desync_cframe(): CFrame` | Gets server CFrame (where you actually are). | Desync | ``cf = api:get_desync_cframe()`` |
| `api:get_lua_name(): string` | Gets the script name. | Utility | ``print(api:get_lua_name())`` |
| `api:get_ragebot_status(): (string, any?)` | Returns status and data (e.g., getting target, buying). | Ragebot | ``status, data = api:get_ragebot_status()`` |
| `api:get_status_cache(player: Player): table?` | Status like K.O, Dead, Armor, Grabbed. | Cache | ``cache = api:get_status_cache(player)`` |
| `api:get_target_cache(type: string): table` | Info on targets (ragebot, aimbot, silent). | Cache | ``cache = api:get_target_cache("ragebot")`` |
| `api:get_tool_cache(): table` | Info about local tool (ammo, gun, etc.). | Cache | ``cache = api:get_tool_cache()`` |
| `api:get_ui_object(flag: string): table?` | Gets a UI object by flag. | Utility | ``api:get_ui_object("silent_toggle"):SetValue(true)`` |
| `api:is_crew(player: Player, target: Player): boolean` | Checks if players are teammates/crew. | Player | ``api:is_crew(p1, p2)`` |
| `api:is_ragebot(): boolean` | Returns true if currently ragebotting. | Ragebot | ``if api:is_ragebot() then ... end`` |
| `api:notify(message: string, lifetime: number?): nil` | Sends a notification. `lifetime` is optional. | Utility | ``api:notify("hello", 10)`` |
| `api:on_command(command: string, callback: function): nil` | Chat command listener. | Misc | ``api:on_command("!cmd", function(plr, args) ... end)`` |
| `api:on_event(name: string, callback: ()->nil): RBXScriptConnection?` | Registers an event listener. | Utility | ``api:on_event("unload", function() ... end)`` |
| `api:override_key_state(key: string \` | table, override: boolean): nil` | Utility | `Forces a keybind state.` |
| `api:ragebot_strafe_override(callback: ...): nil` | Overrides strafe position. callback(pos, unsafe, part). | Ragebot | ``api:ragebot_strafe_override(function(pos, unsafe, part) return CFrame.new(...) end)`` |
| `api:redeem_codes(): nil` | Redeems all available codes. | Misc | ``api:redeem_codes()`` |
| `api:set_desync_cframe(point: CFrame): nil` | Sets desync position for one frame. | Desync | ``api:set_desync_cframe(CFrame.new(0,1000,0))`` |
| `api:set_fake(override: boolean, cframe: CFrame?, refresh: boolean?): nil` | Sets fake position. | Desync | ``api:set_fake(true, CFrame.new(0,1000,0), true)`` |
| `api:set_lua_name(name: string): nil` | Sets the script name for config storage. | Utility | ``api:set_lua_name("my script")`` |
| `api:set_ragebot(enabled: boolean)` | Forces ragebot enabled/disabled (override). | Ragebot | ``api:set_ragebot(true)`` |
| `api:teleport(cframe: CFrame): nil` | Teleports player/vehicle. Yields. | Local | ``api:teleport(CFrame.new(0,10,0))`` |

## 🌐 Global Environment
Globals available in the script environment (Lua 5.1 / Luau + standard exploit env).

| Name | Type |
| :--- | :--- |
| `AntiBox` | table |
| `CartBox` | table |
| `Connections` | table |
| `Drawing` | table |
| `FakeBox` | table |
| `GetObjects` | function |
| `GrenadeBox` | table |
| `GripBox` | table |
| `HttpGet` | function |
| `HttpGetAsync` | function |
| `KeyPress` | function |
| `KeyRelease` | function |
| `Library` | table |
| `Mouse1Click` | function |
| `Mouse1Press` | function |
| `Mouse1Release` | function |
| `Mouse2Click` | function |
| `Mouse2Press` | function |
| `Mouse2Release` | function |
| `MouseMoveABS` | function |
| `MouseMoveAbs` | function |
| `MouseMoveRel` | function |
| `MouseMoveRelative` | function |
| `MouseScroll` | function |
| `NotifyDamageBox` | table |
| `NotifyHitBox` | table |
| `Options` | table |
| `RageBox` | table |
| `RageResolverBox` | table |
| `RotateGrip` | table |
| `SaveManager` | table |
| `SpawnBox` | table |
| `StompBox` | table |
| `Toggles` | table |
| `VoidBox` | table |
| `VoidRageBox` | table |
| `WebSocket` | table |
| `_G` | table |
| `appendfile` | function |
| `base64` | table |
| `base64_decode` | function |
| `base64_encode` | function |
| `base64decode` | function |
| `base64encode` | function |
| `bit` | table |
| `cache` | table |
| `cansignalreplicate` | function |
| `checkcaller` | function |
| `checkclosure` | function |
| `checkinst` | function |
| `cleardrawcache` | function |
| `clonefunction` | function |
| `cloneref` | function |
| `clonereference` | function |
| `compareinstances` | function |
| `create_comm_channel` | function |
| `crypt` | table |
| `debug` | table |
| `decompile` | function |
| `delfile` | function |
| `delfolder` | function |
| `disassemble` | function |
| `dofile` | function |
| `dumpAPIMethods` | function |
| `dumpEverythingToFile` | function |
| `dumpGetgenv` | function |
| `dumpTabs` | function |
| `dumpToggles` | function |
| `dumpUIFlags` | function |
| `dumpstring` | function |
| `exploreTable` | function |
| `filtergc` | function |
| `fireclickdetector` | function |
| `fireproximityprompt` | function |
| `firesignal` | function |
| `firetouchinterest` | function |
| `get_comm_channel` | function |
| `get_hidden_gui` | function |
| `get_thread_identity` | function |
| `getactors` | function |
| `getcallbackmember` | function |
| `getcallbackvalue` | function |
| `getcallingscript` | function |
| `getconnections` | function |
| `getconstant` | function |
| `getconstants` | function |
| `getcustomasset` | function |
| `getexecutorname` | function |
| `getfflag` | function |
| `getfps` | function |
| `getfpscap` | function |
| `getfunctionhash` | function |
| `getgc` | function |
| `getgenv` | function |
| `gethiddenproperty` | function |
| `gethui` | function |
| `gethwid` | function |
| `getidentity` | function |
| `getinfo` | function |
| `getinstances` | function |
| `getloadedmodules` | function |
| `getmenv` | function |
| `getmodules` | function |
| `getnamecallmethod` | function |
| `getnilinstances` | function |
| `getpid` | function |
| `getproto` | function |
| `getprotos` | function |
| `getrawmetatable` | function |
| `getreg` | function |
| `getregistry` | function |
| `getrenderproperty` | function |
| `getrenv` | function |
| `getrunningscripts` | function |
| `getscriptbytecode` | function |
| `getscriptclosure` | function |
| `getscriptfromthread` | function |
| `getscriptfunction` | function |
| `getscripthash` | function |
| `getscripts` | function |
| `getsenv` | function |
| `getsignalarguments` | function |
| `getsimulationradius` | function |
| `getstack` | function |
| `gettenv` | function |
| `getthreadcontext` | function |
| `getthreadidentity` | function |
| `getupvalue` | function |
| `getupvalues` | function |
| `hookfunc` | function |
| `hookfunction` | function |
| `hookmeta` | function |
| `hookmetamethod` | function |
| `http` | table |
| `http_request` | function |
| `identifyexecutor` | function |
| `inspectUIObject` | function |
| `is_parallel` | function |
| `iscclosure` | function |
| `isexecutorclosure` | function |
| `isfile` | function |
| `isfolder` | function |
| `isfunctionhooked` | function |
| `isgameactive` | function |
| `islclosure` | function |
| `isnetworkowner` | function |
| `isnewcclosure` | function |
| `isourclosure` | function |
| `isparallel` | function |
| `isrbxactive` | function |
| `isreadonly` | function |
| `isrenderobj` | function |
| `isscriptable` | function |
| `isvalidlevel` | function |
| `iswindowactive` | function |
| `keypress` | function |
| `keyrelease` | function |
| `listfiles` | function |
| `loadfile` | function |
| `loadstring` | function |
| `lua` | table |
| `lz4compress` | function |
| `lz4decompress` | function |
| `makefolder` | function |
| `makereadonly` | function |
| `makewritable` | function |
| `messagebox` | function |
| `mouse1click` | function |
| `mouse1press` | function |
| `mouse1release` | function |
| `mouse2click` | function |
| `mouse2press` | function |
| `mouse2release` | function |
| `mousemoveabs` | function |
| `mousemoverel` | function |
| `mousescroll` | function |
| `newcclosure` | function |
| `queue_on_teleport` | function |
| `queueonteleport` | function |
| `randomstring` | function |
| `readfile` | function |
| `replaceclosure` | function |
| `replicatesignal` | function |
| `request` | function |
| `require` | function |
| `restorefunc` | function |
| `restorefunction` | function |
| `run_on_actor` | function |
| `saveinstance` | function |
| `set_thread_identity` | function |
| `setclipboard` | function |
| `setconstant` | function |
| `setfflag` | function |
| `setfps` | function |
| `setfpscap` | function |
| `sethiddenproperty` | function |
| `setidentity` | function |
| `setnamecallmethod` | function |
| `setrawmetatable` | function |
| `setrbxclipboard` | function |
| `setreadonly` | function |
| `setrenderproperty` | function |
| `setscriptable` | function |
| `setsimulationradius` | function |
| `setstack` | function |
| `setthreadcontext` | function |
| `setthreadidentity` | function |
| `setupvalue` | function |
| `shared` | table |
| `toclipboard` | function |
| `write_clipboard` | function |
| `writefile` | function |

## 🛠️ UI Object Methods
Methods available on objects returned by `api:get_ui_object()`.

### Common Methods
| Method | Description |
| :--- | :--- |
| `SetValue(val)` | Sets the value of the UI option. |
| `GetValue()` | Gets the current value. |
| `OverrideState(bool)` | Forces a KeyPicker state (on/off). |
| `SetValues(table)` | Updates options for a Dropdown. |
| `Callback(val)` | Manually triggers the callback function. |