technowarp = {}

local function get_node(pos)
    VoxelManip():read_from_map(pos, pos)
    return minetest.get_node(pos)
end

local function is_warp(name)
    return (minetest.get_item_group(name, "warper") or 0) > 0
end

function technowarp.register(name, d)
    local function fs(pos, meta)
        meta:set_string("formspec", "size[3.75,1.25]field[0.25,0.25;3.75,1;channel;Channel:;${channel}]label[0,1;Position: " .. minetest.pos_to_string(pos) .. "]")
    end

    local function reply(pos, msg)
        digiline:receptor_send(pos, digiline.rules.default, minetest.get_meta(pos):get_string("channel"), msg)
    end

    local names = {
        active = name .. "_active",
        inactive = name,
    }

    local class = {
        lc = d.class:lower(),
        uc = d.class:upper(),
    }

    local desc = class.uc .. " Warper"

    for _,active in ipairs{true, false} do
        minetest.register_node(active and names.active or names.inactive, {
            description = desc,
            tiles = active and d.active_tiles or d.tiles,
            groups = {cracky = 1, level = 2, technic_machine = 1, ["technic_" .. class.lc] = 1, warper = 1,
                not_in_creative_inventory = (active and 1 or 0)},
            drop = names.inactive,

            on_construct = function(pos)
                local meta = minetest.get_meta(pos)
                fs(pos, meta)
                meta:set_int(class.uc .. "_EU_demand", d.demand)
                meta:set_string("infotext", desc .. " Unpowered")
            end,

            technic_disabled_machine_name = names.inactive,
            technic_run = function(pos, node)
                local meta = minetest.get_meta(pos)
                local eu_input = meta:get_int(class.uc .. "_EU_input")
                local eu_demand = meta:get_int(class.uc .. "_EU_demand")
                local powered = eu_input >= eu_demand
                if powered then
                    meta:set_string("infotext", desc .. " Powered")
                    if not active then
                        node.name = names.active
                        minetest.swap_node(pos, node)
                    end
                    meta:set_int(class.uc .. "_EU_demand", 0)
                else
                    meta:set_string("infotext", desc .. " Unpowered")
                    if active then
                        node.name = names.inactive
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
                            if vector.distance(pos, dest) > d.distance then
                                return reply(pos, {type = "error", error = "distance"})
                            end
                            if not is_warp(get_node(dest).name) then
                                return reply(pos, {type = "error", error = "noreceiver"})
                            end
                            if active then
                                for _,p in ipairs(minetest.get_connected_players()) do
                                    if p:get_player_name() == msg.name and vector.equals(vector.round(p:getpos()), vector.add(pos, vector.new(0, 1, 0))) then
                                        meta:set_int(class.uc .. "_EU_demand", d.demand)
                                        p:setpos(vector.add(dest, vector.new(0, 1, 0)))
                                        if tonumber(msg.yaw) then
                                            p:set_look_horizontal(tonumber(msg.yaw))
                                        end
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
    end

    technic.register_machine(class.uc, names.active, technic.receiver)
    technic.register_machine(class.uc, names.inactive, technic.receiver)
end

technowarp.register("technowarp:lv_warper", {
    tiles = {"technowarp_lv.png"},
    active_tiles = {"technowarp_lv.png^technowarp_active.png"},
    demand = 11 * 1000,
    distance = 2000,
    class = "lv",
})

minetest.register_craft{
    output = "technowarp:lv_warper",
    recipe = {
        {"mesetech:active_mese_1", "technic:lv_transformer", "mesetech:active_mese_1"},
        {"technic:red_energy_crystal", "mesecons_luacontroller:luacontroller0000", "technic:red_energy_crystal"},
        {"default:steelblock", "technic:lv_cable", "default:steelblock"},
    },
}

technowarp.register("technowarp:mv_warper", {
    tiles = {"technowarp_mv.png"},
    active_tiles = {"technowarp_mv.png^technowarp_active.png"},
    demand = 230 * 1000,
    distance = 12000,
    class = "mv",
})

minetest.register_craft{
    output = "technowarp:mv_warper",
    recipe = {
        {"mesetech:active_mese_2", "technic:mv_transformer", "mesetech:active_mese_2"},
        {"technic:green_energy_crystal", "technowarp:lv_warper", "technic:green_energy_crystal"},
        {"technic:carbon_steel_block", "technic:mv_cable", "technic:carbon_steel_block"},
    },
}

technowarp.register("technowarp:hv_warper", {
    tiles = {"technowarp_hv.png"},
    active_tiles = {"technowarp_hv.png^technowarp_active.png"},
    demand = 1100 * 1000,
    distance = 200000,
    class = "hv",
})

minetest.register_craft{
    output = "technowarp:hv_warper",
    recipe = {
        {"mesetech:active_mese_3", "technic:hv_transformer", "mesetech:active_mese_3"},
        {"technic:blue_energy_crystal", "technowarp:mv_warper", "technic:blue_energy_crystal"},
        {"technic:carbon_steel_block", "technic:hv_cable", "technic:carbon_steel_block"},
    },
}
