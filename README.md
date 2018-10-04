# TechnoWarp
* Acts upon players standing over the warp device.
* Players will be teleported immediately above the destination receiver.
* Receiving warpers do not require power.

# Dependencies
* default
* Technic
* Digilines
* Mesecons
* [MeseTech](https://github.com/tigris-mt/mesetech)

# API
## Actions
* `{type = "warp", name = <name>, dest = <vector>, yaw = <optional angle in radians>}`
## Errors
* `{type = "error", error = "noreceiver"}`
* `{type = "error", error = "notfound", name = <name>}`
* `{type = "error", error = "power"}`
* `{type = "error", error = "distance"}`
## Events
* `{type = "event", event = "warped", name = "singleplayer", to = <vector>}`
* `{type = "event", event = "arrived", name = "singleplayer", from = <vector>}`
