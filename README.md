# TechnoWarp
* Acts upon players standing over the warp device.
* Players will be teleported immediately above the destination receiver.
* Receiving warpers do not require power.
# API
## Actions
* `{type = "warp", name = <name>, dest = <vector>}`
## Errors
* `{type = "error", error = "noreceiver"}`
* `{type = "error", error = "notfound", name = <name>}`
* `{type = "error", error = "power"}`
## Events
* `{type = "event", event = "warped", name = "singleplayer", to = <vector>}`
* `{type = "event", event = "arrived", name = "singleplayer", from = <vector>}`
