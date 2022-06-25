--[[
* l_hitdisplay.lua
* (sprkizard)
* (Jun 8, 2022 17:27)
* Desc: Custom boss meter display


* Usage: TODO
]]


-- TODO: recover amount display - drain(+)/flash() damagetype - start sound - force flash damage
rawset(_G, "HitDisplay", {})

local health_tab = {}


local function altval(v, av)
	return (v and not nil) and v or av
end

local function clamp(v, i, o)
	return min(max(v, i), o)
end


function HitDisplay.shownew(mo, disparg)

	local disp = {}

	disparg = altval(disparg, {})

	disp["mobj"] = mo
	disp["identifier"] = disparg.identifier or "hitdisplay"
	-- Drawing Origin
	disp["drawx"] = altval(disparg.drawx, 8)
	disp["drawy"] = altval(disparg.drawy, 96)
	-- HP drawing offset / graphics / empty flag / width scale / maxhealth
	disp["hp_drawx"] = altval(disparg.hp_drawx, 0)
	disp["hp_drawy"] = altval(disparg.hp_drawy, 0)
	disp["hpfill"] = disparg.hpfill or "CROSHAI3"
	disp["hphurt"] = disparg.hphurt or "CROSHAI3"
	disp["hpempty"] = disparg.hpempty or "CROSHAI1"
	disp["hpempty_flags"] = disparg.hpempty_flags or 0
	disp["boxwidth"] = altval(disparg.boxwidth, 16)
	disp["boxheight"] = altval(disparg.boxheight, 1)
	disp["maxhealth"] = altval(disparg.maxhealth, 8) -- mo.info.spawnhealth
	-- Enemy name / text alignment / drawing offset
	disp["enemyname"] = disparg.enemyname or "ENEMY"
	disp["enemyname_align"] = disparg.enemyname_align or "left"
	disp["name_drawx"] = altval(disparg.name_drawx, 0)
	disp["name_drawy"] = altval(disparg.name_drawy, -12)
	-- Border graphic
	disp["border"] = disparg.border or "CROSHAI1"

	-- removes meter on 0 automatically
	disp["removeonempty"] = disparg.removeonempty

	-- Hurt timer tree reference variable / sliding damage value
	disp["hurtref"] = disparg.hurtref
	disp["dmgref"] = altval(mo.health, 0)

	-- First time use
	disp["setup"] = true
	disp["fillref"] = 0
	disp["displaysound"] = disparg.displaysound or sfx_ding

	-- Extra vars
	disp["var1"] = disparg.var1
	disp["var2"] = disparg.var2

	table.insert(health_tab, disp)

	return HitDisplay
end

-- removes by identifier or enemyname
function HitDisplay.remove(identifier, byenemyname)
	for i=1, #health_tab do

		local t = health_tab[i]

		if (byenemyname and t["enemyname"] == identifier)
		or (t["identifier"] == identifier) then
			table.remove(health_tab, i)
		end
	end
end

function HitDisplay.clearall()
	for i=1, #health_tab do
		table.remove(health_tab, i)
	end
end

-- Shortcut to remove and add a new meter
function HitDisplay.refill(identifier, byenemyname, mo, disparg)
	HitDisplay.remove(identifier, byenemyname)
	HitDisplay.shownew(mo, disparg)
end

-- Shortcut to just set mobj health
function HitDisplay.sethealth(mobj, newhealth, relative)
	if mobj then
		mobj.health = (relative) and $1+newhealth or newhealth
	end
end

function HitDisplay.meterdisplay(v, stplyr)

	for i=1, #health_tab do
		local meow = health_tab[i]

		-- automatic removal on empty (TODO: thinkframe?)
		if meow.removeonempty and meow.mobj.health <= 0 then table.remove(health_tab, i) end

		-- Drawing start origin
		local startx = meow.drawx
		local starty = meow.drawy
		-- HP offset
		local hpx = (meow.drawx+meow.hp_drawx)
		local hpy = (meow.drawy+meow.hp_drawy)
		-- HP width calc
		local hpfillwidth = FixedFloor(FU*(meow.mobj.health*meow.boxwidth/meow.maxhealth))
		local dmgfillwidth = FixedFloor(FU*(meow.dmgref*meow.boxwidth/meow.maxhealth))
		-- Name offset
		local namex = (meow.drawx+meow.name_drawx)
		local namey = (meow.drawy+meow.name_drawy)
		-- Name string
		local enemyname = meow.enemyname
		-- cached graphics
		local enemywindow_g = v.cachePatch(meow.border)
		local enemyfill_g = v.cachePatch(meow.hpfill)
		local enemyhurt_g = v.cachePatch(meow.hphurt)
		local enemyempty_g = v.cachePatch(meow.hpempty)
		-- Toggles when character limit goes past 13
		local thintoggle = (enemyname:len() > 13) and "thin-" or ""


		-- Damage color (Background)
		v.drawStretched(FU*hpx, FU*hpy, FU*(meow.boxwidth), FU*meow.boxheight, enemyempty_g, meow.hpempty_flags, v.getColormap(1))

		-- Reference damage to ease to when damage is added or subtracted (Hurt timer mandatory)
		if meow.dmgref < meow.mobj.health and not meow.mobj[meow.hurtref] then
			meow.dmgref = $ + 1
		elseif meow.dmgref > meow.mobj.health and not meow.mobj[meow.hurtref] then
			meow.dmgref = $ - 1
		end

		-- Damage color (Reference)
		v.drawStretched(FU*hpx, FU*hpy, abs(dmgfillwidth), FU*meow.boxheight, enemyhurt_g, 0, v.getColormap(1))

		-- Damage color (Main)
		if (meow.mobj.health > 0) then
			v.drawStretched(FU*hpx, FU*hpy, abs(hpfillwidth), FU*meow.boxheight, enemyfill_g, 0, v.getColormap(1))
		end

		-- Enemy Border
		v.drawStretched(FU*meow.drawx, FU*meow.drawy, FU, FU, enemywindow_g, 0, v.getColormap(1))

		-- Enemy Name
		v.drawString(namex, namey, enemyname, V_ALLOWLOWERCASE, thintoggle .. meow.enemyname_align)
		

		-- Fill startup
		if (meow.fillref < meow.mobj.health and meow.setup)

			-- Scales amount based on boxwidth and maximum health
			-- TODO: properly insert formula to account for values > 45, < 45 to fill 1.2 seconds evenly
			meow.fillref = $1+(1+(meow.maxhealth/meow.boxwidth)*2)

			-- Sound plays at different rate
			if (leveltime*2) % 5 < 2 then S_StartSound(nil, meow.displaysound, stplyr) end

			v.drawStretched(FU*hpx, FU*hpy, FU*(meow.boxwidth), FU*meow.boxheight, enemyempty_g, 0, v.getColormap(1))
			v.drawStretched(FU*hpx, FU*hpy, FU*(meow.fillref*meow.boxwidth/meow.maxhealth), FU*meow.boxheight, enemyfill_g, 0, v.getColormap(1))
			
			meow.setup = (meow.fillref > meow.mobj.health) and false or true
		end

		-- v.drawFill(320/2, 160/2, (meow.extra and meow.mobj[meow.extra].health or meow.mobj.health), 6, 35)
		-- v.drawFill(320/2, 160/2, meow.health/meow.maxhealth, 6, 35)

		-- v.drawString(96, 96, string.format("%d / %d", meow.mobj.health, meow.maxhealth), 0, "left")
		-- v.drawString(96, 96, ((leveltime*2) % 5), 0, "left")
	end
end

function HitDisplay.netvars(n)
	health_tab = n($)
end



hud.add(HitDisplay.meterdisplay, "game")
addHook("MapLoad", HitDisplay.clearall)
addHook("MapChange", HitDisplay.clearall)
addHook("NetVars", HitDisplay.netvars)

