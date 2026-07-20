--[[
* frameanimate.lua
* (Author: sprki_zard)
* (June 6, 2020 23:29)
* Desc: n/a
*
* Notes: n/a
]]
rawset(_G, "FrameAnim", {})

FrameAnim.playing = {}


-- Adds a new animation to the playing animation list
function FrameAnim.add(animname, animator, nsprite, startf, endf, args, use_dupe)

	-- Duplicate animation? Set it to be replaced immediately
	if not (use_dupe) then
		for i,anim in ipairs(FrameAnim.playing) do
			if (anim.name == animname) then
				anim.deleted = true
			end
		end
	end

	-- Create Animation Table
	local anim = {
		name=animname,
		mobj=animator,
		sprite=nsprite,
		timer=0,
		frame=R_Char2Frame(startf), --startf,
		startframe=(args and args.loopframe and R_Char2Frame(args.loopframe)) or R_Char2Frame(startf), --startf,
		endframe=R_Char2Frame(endf or startf), --endf,
		loop=(args and args.loop) or ((R_Char2Frame(endf)-R_Char2Frame(startf)) * ((args and args.delay) or 1)), -- if no loop, set to end frame (ef*delay for slower animations)
		forever=(args and args.loopalways),
		frameskip=(args and args.frameskip) or 1, -- TODO: implement frameskip
		delay=(args and args.delay) or 1,
		flag=(args and args.flag) or 0, -- TODO: sprite flag that applies to separate frames. currently does not work.
		-- spritelist = {}, -- TODO: separate flags per frame?
		paused=false,
		deleted=false,
	}

	-- Throw it into the playing list
	table.insert(FrameAnim.playing, anim)

	--Set object to these frames
	animator.sprite = nsprite
	animator.frame = anim.frame | anim.flag

	-- print("Inserted Animation: "..animname)
end

-- add wrapper for spr2 animations
function FrameAnim.addspr2(spr2animname, animator, spr2, framestart, frameend, animargs, use_dupe)

	local skin = false -- animargs and animargs.skin

	-- Set skin if given one (used for objects, not a good idea for players)
	if skin then animator.skin = skin end

	-- Set spr2 frame
	animator.sprite2 = spr2

	-- Super frame swapper
	if animargs and animargs.super then
		animator.sprite2 = $1 | FF_SPR2SUPER
	end

	-- TODO: report to issues: SPR2_STND cannot be accessed with skin.sprites[]
	local maxframe = 0
	if (spr2 == SPR2_STND) then
		maxframe = frameend
	else
		maxframe = R_Frame2Char(skins[animator.skin].sprites[spr2].numframes-1)
	end

	-- FrameAnim.add("anim_spr2_play", player.mo, SPR_PLAY, framestart or "A", frameend or maxframe, animargs)
	FrameAnim.add("anim_spr2_" .. spr2animname, animator, SPR_PLAY, framestart or "A", frameend or maxframe, animargs, use_dupe)
end

-- Seeks an animation and runs a function when found (also returns true if exists, false if not)
function FrameAnim.seek(animname, callback)
	for i,anim in ipairs(FrameAnim.playing) do
		if (anim.name == animname) then
			if (callback) then 
				do callback(anim) end
			end
			return true
		end
	end
	return false
end

-- Removes one or all animations
function FrameAnim.remove(animname, removeall)
	if (removeall) then
		for i=1, #FrameAnim.playing do
			FrameAnim.playing[i].deleted = true 
		end
	else
		FrameAnim.seek(animname, function(an) an.deleted = true end)
	end
end

-- Pauses an animation
function FrameAnim.pause(animname, ispaused)
	FrameAnim.seek(animname, function(an) an.paused = ispaused end)
end

-- Checks if an animation just finished
function FrameAnim.checkexisting(animname)
	return FrameAnim.seek(animname)
end

-- ================
-- Event Extension
-- Checks if a certain script is loaded to extend some of it's features
function FrameAnim.EventExists()
	if not _G["Event"] then print("(!)\x82 This function requires 'Event' to work!") return false else return true end
end

-- Add a custom wrapper event + others when the companion script exists
if FrameAnim.EventExists() then

	-- Suspends an event until the animation ends
	function FrameAnim.waitframedone(event, animname)
		if (FrameAnim.checkexisting(animname)) then Event.pause(event) else Event.resume(event) end
	end
-- else
-- 	local handler_str = "(!)\x82 Function [FrameAnim.waitframedone] requires 'Event' to work, is it available?"
	
-- 	function FrameAnim.waitframedone()
-- 		print(handler_str)
-- 	end
end

-- ================


-- The thinker function that handles animations
function FrameAnim.Thinker()

	for i=1, #FrameAnim.playing do
		
		local anim = FrameAnim.playing[i]

		-- Remove if animation is set to be deleted
		if (anim and anim.deleted) then
			table.remove(FrameAnim.playing, i)
		end

		-- no mobj means to not continue
		if anim and not (anim.mobj and anim.mobj.valid) then 
			anim.deleted = true
		end

		-- Continue next iteration if animation is set to be deleted, otherwise continue
		(function()
			if (anim and not anim.deleted) then

				-- Set sprite
				anim.mobj.sprite = anim.sprite
				anim.mobj.frame = anim.frame | anim.flag

				-- the animation is paused
				if (anim.paused) then return end

				-- increase animation timer
				anim.timer = $ + 1

				-- loop on time, or loop forever
				if (anim.loop > 0 or anim.forever) then

					-- Play the sprite's frames by set speed and delay
					if (anim.timer % anim.delay == 0) then
						anim.frame = ($1+1 * anim.frameskip)
					end

					-- Reset the framecount to the beginning
					if (anim.frame > anim.endframe) then
						anim.frame = anim.startframe
					end

					anim.loop = anim.forever and 1 or $1-1
				else
					-- When our sprite loop time has ended, set the animation to be removed
					anim.deleted = true
					-- print(string.format("animation [%s] finished", anim.name))
				end

				--[[-- Play the sprite's frames by set speed and delay
				if (anim.timer % anim.delay == 0) then
					anim.frame = $1+1 * anim.speed
				end

				-- Reset the framecount to the beginning
				if (anim.frame > anim.endframe) then
					anim.frame = anim.startframe
				end

				-- Set sprite again
				anim.mobj.frame = anim.frame | anim.flag

				-- When our sprite loop time has ended, set the animation to be removed
				if (anim.loop <= 0 and not anim.forever) then
					anim.deleted = true
					-- print("animation finished")
					return
				else
					anim.loop = $1-1
				end--]]
			end
		end)()
	end

end

function FrameAnim.netvars(n)
	FrameAnim.playing = n($)

	--[[local a = #FrameAnim.playing
	a = n(a)
	for i = 1, a do
		FrameAnim.playing[i] = n($)
	end--]]
end



-- Uncomment for Example
--[[addHook("NetVars", function(network)
	FrameAnim.netvars(network)
end)

addHook("ThinkFrame", function()
	FrameAnim.Thinker()
end)--]]
--[[addHook("ThinkFrame", function()

	-- Checks for existing
	print(FrameAnim.checkexisting("existing"))

	if leveltime == 2*TICRATE then 
		local s = P_SpawnMobj(-64*FU, -96*FU, 32*FU, MT_PULL)
		-- FrameAnim.add("name", s, SPR_EGGM, A, F)
		-- FrameAnim.add("name", s, SPR_EGGM, V, W, {loop=2*TICRATE})
		-- FrameAnim.add("name", s, SPR_PIKE, A, P)
		FrameAnim.add("name", s, SPR_GFZD, R_Frame2Char(0), R_Frame2Char(31), {loop=10*TICRATE})
	end

	if leveltime == 7*TICRATE then 
		-- FrameAnim.pause("name", true)
	end

	if leveltime == 10*TICRATE then 
		-- FrameAnim.remove("name", true)
	end

	if leveltime == 8*TICRATE then
		local s = P_SpawnMobj(-64*FU, -96*FU, 64*FU, MT_PULL)
		FrameAnim.add("existing", s, SPR_EGGM, "V", "W", {loop=8*TICRATE, delay=15})
	end
end)
--]]
