temp_inv = {}

-- formspec setup
local function get_treasure_chest_formspec(pos, taker)
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local formspec =
		"size[8,9]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"list[nodemeta:" .. spos .. ";" .. taker .. ";0,0.3;8,4;]" ..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6.08;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";" .. taker .. "]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0,4.85)
 return formspec
end

-- check to see if player is chest owner
local function has_treasure_chest_privilege(meta, player)
	if player:get_player_name() ~= meta:get_string("owner") then
		return false
	end
	return true
end

-- register treasure chest node
minetest.register_node("treasurechest:empty", {
	paramtype = "light",
	drawtype = "mesh",
	mesh = "treasurechest.obj",
	description = "Treasure Chest",
	tiles = {"treasurechest_wood.png"},
	paramtype2 = "facedir",
	selection_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -6/16, 0.5,1/4, 6/16 },
	},
	groups = {choppy=2,oddly_breakable_by_hand=2,not_in_creative_inventory=1},
	sounds = default.node_sound_wood_defaults(),

	-- set owner and inventory size of treasure chest after placing it
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local giver = placer:get_player_name()
		meta:set_string("owner", giver or "")
		meta:set_string("infotext", "Treasure Chest (owned by "..giver..")")
		inv:set_size(giver, 8*4)
	end,

	-- only allow owner to remove chest
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		return has_treasure_chest_privilege(meta, player)
	end,

	-- remove all metadata from node when chest is removed
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		minetest.set_node(pos, {name="air"})
	end,

	-- only allow owner to move items around within chest
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if not has_treasure_chest_privilege(meta, player) then
			return 0
		end
		return count
	end,
 
	-- only allow owner to add items to chest
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if not has_treasure_chest_privilege(meta, player) then
			return 0
		end
		return stack:get_count()
	end,

	-- checks if player has previously examined contents of chest and allows them to remove available items
	-- also allows owner to add items to chest
 	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)		
		local taker = clicker:get_player_name() 
		local giver = meta:get_string("owner")
		local taken = meta:get_string(taker)
		local inv = meta:get_inventory()
		-- if first time examining chest, creates new inventory, copying the owner's inventory
		if taken ~= "yes" then
			inv:set_size(taker, 8*4)		
			for i=1,32 do
				temp_inv = inv:get_stack(giver, i)
				inv:set_stack(taker, i, temp_inv)
			end	
			meta:set_string(taker, "yes")		
		end
		minetest.show_formspec(
			taker,
			"treasurechest:empty",
			get_treasure_chest_formspec(pos, taker)
		)	
	end,
	
})

print("[Mod]treasurechest Loaded!")
