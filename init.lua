technowarp = {
    -- 1.9 MEU demand. This requires at least 5 HV batteries.
    demand = 1.9 * 1000 * 1000,
}

local function get_node(pos)
    VoxelManip():read_from_map(pos, pos)
    return minetest.get_node(pos)
end

local function is_warp(name)
    return name == "technowarp:on" or name == "technowarp:off"
end

local function r(n, d)
    local function fs(pos, meta)
        meta:set_string("formspec", "size[3.75,1.25]field[0.25,0.25;3.75,1;channel;Channel:;${channel}]label[0,1;Position: " .. minetest.pos_to_string(pos) .. "]")
    end

    local function reply(pos, msg)
        digiline:receptor_send(pos, digiline.rules.default, minetest.get_meta(pos):get_string("channel"), msg)
    end

    minetest.register_node("technowarp:" .. n, {
        description = "HV Warper",
        tiles = {"technowarp_" .. n .. ".png"},
        groups = {cracky = 1, level = 2, technic_machine = 1, technic_hv = 1,
            not_in_creative_inventory = (d.active and 1 or 0)},
        drop = "technowarp:off",

        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            fs(pos, meta)
            meta:set_int("HV_EU_demand", technowarp.demand)
            meta:set_string('infotext', "HV Warper Unpowered")
        end,

        technic_disabled_machine_name = "technowarp:off",
        technic_run = function(pos, node)
            local meta = minetest.get_meta(pos)
            local eu_input = meta:get_int("HV_EU_input")
            local eu_demand = meta:get_int("HV_EU_demand")
            local powered = eu_input >= eu_demand
            if powered then
                meta:set_string('infotext', "HV Warper Powered")
                if not d.active then
                    node.name = "technowarp:on"
                    minetest.swap_node(pos, node)
                end
                meta:set_int('HV_EU_demand', 0)
            else
                meta:set_string('infotext', "HV Warper Unpowered")
                if d.active then
                    node.name = "technowarp:off"
                    minetest.swap_node(pos, node)
                end
            end
        end,

        on_receive_fields = function(pos, _, fields, sender)
            if not minetest.is_protected(pos, sender:get_player_name()) then
                if fields.channel then
                    minetest.get_meta(pos):set_string("channel", fields.channel)
                end
            end
        end,

        digiline = {
            receptor = {},
            effector = {
                action = function(pos, node, channel, msg)
                    local meta = minetest.get_meta(pos)
                    if meta:get_string("channel") ~= channel then
                        return
                    end
                    if type(msg) ~= "table" or not msg.type then
                        return
                    end

                    if msg.type == "warp" then
                        local dest = msg.dest
                        if type(dest) ~= "table" or type(dest.x) ~= "number" or type(dest.y) ~= "number" or type(dest.z) ~= "number" then
                            return reply(pos, {type = "error", error = "noreceiver"})
                        end
                        dest = vector.round(dest)
                        if not is_warp(get_node(dest).name) then
                            return reply(pos, {type = "error", error = "noreceiver"})
                        end
                        if d.active then
                            for _,p in ipairs(minetest.get_connected_players()) do
                                if p:get_player_name() == msg.name and vector.equals(vector.round(p:getpos()), vector.add(pos, vector.new(0, 1, 0))) then
                                    meta:set_int('HV_EU_demand', technowarp.demand)
                                    p:setpos(vector.add(dest, vector.new(0, 1, 0)))
                                    reply(pos, {type = "event", event = "warped", name = msg.name, to = dest})
                                    reply(dest, {type = "event", event = "arrived", name = msg.name, from = pos})
                                    return
                                end
                            end
                            reply(pos, {type = "error", error = "notfound", name = msg.name})
                        else
                            reply(pos, {type = "error", error = "power"})
                        end
                    end
                end,
            },
        },
    })

    technic.register_machine("HV", "technowarp:" .. n, technic.receiver)
end

r("on", {
    active = true,
})

r("off", {
    active = false,
})

minetest.register_craft{
    output = "technowarp:off",
    recipe = {
        {"mesetech:active_mese_3", "technic:blue_energy_crystal", "mesetech:active_mese_3"},
        {"technic:blue_energy_crystal", "mesecons_luacontroller:luacontroller0000", "technic:blue_energy_crystal"},
        {"technic:stainless_steel_block", "technic:hv_cable0", "technic:stainless_steel_block"},
    },
}
