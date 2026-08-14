--- mod-backend.lua
print "YOOOO"
poptions = {}

do
local __use_percent = true
local allPlayers = {}
for i=1,(players or 2) do
	table.insert(allPlayers, i)
end

function table.contains(t, v, k)
	for k,vv in pairs(t) do
		if k and v[k] == vv[k] or v == vv then
			return true
		end
	end
end


-- make it work with poptions
local __modFuncs = {}
local function __definemod_internal(mod)
	for plr=1,players do
		if not __modFuncs[plr] then __modFuncs[plr] = {} end
		__modFuncs[plr][mod] = {
			get = _G["__get_"..mod.."-"..(plr - 1)],
			set = _G["__set_"..mod.."-"..(plr - 1)],
			isPercent = _G["__isPercent_"..mod.."-"..(plr - 1)],
		}
	end
end

local sqrt = math.sqrt

local sin = math.sin

local asin = math.asin

local cos = math.cos

local pow = math.pow

local exp = math.exp

local pi = math.pi

local abs = math.abs



-- ===================================================================== --



-- Utility functions


--- Flip any easing function, making it go from 1 to 0

-- Example use:

-- ```lua

-- ease {0, 20, flip(outQuad), 50, 'modname'}

-- ```

flip = setmetatable({}, {

__call = function(self, fn)

	self[fn] = self[fn] or function(x)

		return 1 - fn(x)

	end

	return self[fn]

end,

})



-- Mix two easing functions together into a new ease

-- the new ease starts by acting like the first argument, and then ends like the second argument

-- Example: ease {0, 20, blendease(inQuad, outQuad), 100, 'modname'}

blendease = setmetatable({}, {

__index = function(self, key)

	self[key] = {}

	return self[key]

end,

__call = function(self, fn1, fn2)

	if not self[fn1][fn2] then

		local transient1 = fn1(1) <= 0.5

		local transient2 = fn2(1) <= 0.5

		if transient1 and not transient2 then

			error("blendease: the first argument is a transient ease, but the second argument doesn't match")

		end

		if transient2 and not transient1 then

			error("blendease: the second argument is a transient ease, but the first argument doesn't match")

		end

		self[fn1][fn2] = function(x)

			local mixFactor = 3 * x ^ 2 - 2 * x ^ 3

			return (1 - mixFactor) * fn1(x) + mixFactor * fn2(x)

		end

	end

	return self[fn1][fn2]

end,

})


-- Declare an easing function taking one custom parameter

function with1param(fn, defaultparam1)
	return function(t)
		return fn(t, defaultparam1)
	end
end

-- Declare an easing function taking two custom parameters

function with2params(fn, defaultparam1, defaultparam2)
	return function(t)
		return fn(t, defaultparam1, defaultparam2)
	end
end



-- ===================================================================== --



-- Easing functions



function bounce(t)

return 4 * t * (1 - t)

end

function tri(t)

return 1 - abs(2 * t - 1)

end

function bell(t)

return inOutQuint(tri(t))

end

function pop(t)

return 3.5 * (1 - t) * (1 - t) * sqrt(t)

end

function tap(t)

return 3.5 * t * t * sqrt(1 - t)

end

function pulse(t)

return t < 0.5 and tap(t * 2) or -pop(t * 2 - 1)

end



function spike(t)

return exp(-10 * abs(2 * t - 1))

end

function inverse(t)

return t * t * (1 - t) * (1 - t) / (0.5 - t)

end



local function popElasticInternal(t, damp, count)

return (1000 ^ -(t ^ damp) - 0.001) * sin(count * pi * t)

end



local function tapElasticInternal(t, damp, count)

return (1000 ^ -((1 - t) ^ damp) - 0.001) * sin(count * pi * (1 - t))

end



local function pulseElasticInternal(t, damp, count)

if t < 0.5 then

	return tapElasticInternal(t * 2, damp, count)

else

	return -popElasticInternal(t * 2 - 1, damp, count)

end

end



popElastic = with2params(popElasticInternal, 1.4, 6)

tapElastic = with2params(tapElasticInternal, 1.4, 6)

pulseElastic = with2params(pulseElasticInternal, 1.4, 6)



impulse = with1param(function(t, damp)

t = t ^ damp

return t * (1000 ^ -t - 0.001) * 18.6

end, 0.9)



function instant()

return 1

end

function linear(t)

return t

end

function inQuad(t)

return t * t

end

function outQuad(t)

return -t * (t - 2)

end

function inOutQuad(t)

t = t * 2

if t < 1 then

	return 0.5 * t ^ 2

else

	return 1 - 0.5 * (2 - t) ^ 2

end

end

function outInQuad(t)
t = t * 2

if t < 1 then

	return 0.5 - 0.5 * (1 - t) ^ 2

else

	return 0.5 + 0.5 * (t - 1) ^ 2

end

end

function inCubic(t)

return t * t * t

end

function outCubic(t)

return 1 - (1 - t) ^ 3

end
function inOutCubic(t)

t = t * 2

if t < 1 then

	return 0.5 * t ^ 3

else

	return 1 - 0.5 * (2 - t) ^ 3

end

end

function outInCubic(t)

t = t * 2

if t < 1 then

	return 0.5 - 0.5 * (1 - t) ^ 3

else

	return 0.5 + 0.5 * (t - 1) ^ 3

end

end

function inQuart(t)

return t * t * t * t

end

function outQuart(t)

return 1 - (1 - t) ^ 4

end

function inOutQuart(t)

t = t * 2

if t < 1 then

	return 0.5 * t ^ 4

else

	return 1 - 0.5 * (2 - t) ^ 4

end

end

function outInQuart(t)

t = t * 2

if t < 1 then

	return 0.5 - 0.5 * (1 - t) ^ 4

else

	return 0.5 + 0.5 * (t - 1) ^ 4

end

end

function inQuint(t)

return t ^ 5

end

function outQuint(t)

return 1 - (1 - t) ^ 5

end

function inOutQuint(t)

t = t * 2

if t < 1 then

	return 0.5 * t ^ 5

else

	return 1 - 0.5 * (2 - t) ^ 5

end

end

function outInQuint(t)

t = t * 2

if t < 1 then

	return 0.5 - 0.5 * (1 - t) ^ 5

else

	return 0.5 + 0.5 * (t - 1) ^ 5

end

end

function inExpo(t)

return 1000 ^ (t - 1) - 0.001

end

function outExpo(t)

return 1.001 - 1000 ^ -t

end

function inOutExpo(t)

t = t * 2

if t < 1 then

	return 0.5 * 1000 ^ (t - 1) - 0.0005

else

	return 1.0005 - 0.5 * 1000 ^ (1 - t)

end

end

function outInExpo(t)

if t < 0.5 then

	return outExpo(t * 2) * 0.5

else

	return inExpo(t * 2 - 1) * 0.5 + 0.5

end

end

function inCirc(t)

return 1 - sqrt(1 - t * t)

end

function outCirc(t)

return sqrt(-t * t + 2 * t)

end

function inOutCirc(t)

t = t * 2

if t < 1 then

	return 0.5 - 0.5 * sqrt(1 - t * t)

else

	t = t - 2

	return 0.5 + 0.5 * sqrt(1 - t * t)

end

end

function outInCirc(t)

if t < 0.5 then

	return outCirc(t * 2) * 0.5

else

	return inCirc(t * 2 - 1) * 0.5 + 0.5

end

end

function outBounce(t)

if t < 1 / 2.75 then

	return 7.5625 * t * t

elseif t < 2 / 2.75 then

	t = t - 1.5 / 2.75

	return 7.5625 * t * t + 0.75

elseif t < 2.5 / 2.75 then

	t = t - 2.25 / 2.75

	return 7.5625 * t * t + 0.9375

else

	t = t - 2.625 / 2.75

	return 7.5625 * t * t + 0.984375

end

end

function inBounce(t)

return 1 - outBounce(1 - t)

end

function inOutBounce(t)

if t < 0.5 then

	return inBounce(t * 2) * 0.5

else

	return outBounce(t * 2 - 1) * 0.5 + 0.5

end

end

function outInBounce(t)

if t < 0.5 then

	return outBounce(t * 2) * 0.5

else

	return inBounce(t * 2 - 1) * 0.5 + 0.5

end

end

function inSine(x)

return 1 - cos(x * (pi * 0.5))

end

function outSine(x)

return sin(x * (pi * 0.5))

end

function inOutSine(x)

return 0.5 - 0.5 * cos(x * pi)

end

function outInSine(t)

if t < 0.5 then

	return outSine(t * 2) * 0.5

else

	return inSine(t * 2 - 1) * 0.5 + 0.5

end

end



function outElasticInternal(t, a, p)

return a * pow(2, -10 * t) * sin((t - p / (2 * pi) * asin(1 / a)) * 2 * pi / p) + 1

end

local function inElasticInternal(t, a, p)

return 1 - outElasticInternal(1 - t, a, p)

end

function inOutElasticInternal(t, a, p)

return t < 0.5 and 0.5 * inElasticInternal(t * 2, a, p) or 0.5 + 0.5 * outElasticInternal(t * 2 - 1, a, p)

end

function outInElasticInternal(t, a, p)

return t < 0.5 and 0.5 * outElasticInternal(t * 2, a, p) or 0.5 + 0.5 * inElasticInternal(t * 2 - 1, a, p)

end



inElastic = with2params(inElasticInternal, 1, 0.3)

outElastic = with2params(outElasticInternal, 1, 0.3)

inOutElastic = with2params(inOutElasticInternal, 1, 0.3)

outInElastic = with2params(outInElasticInternal, 1, 0.3)



function inBackInternal(t, a)

return t * t * (a * t + t - a)

end

function outBackInternal(t, a)

t = t - 1

return t * t * ((a + 1) * t + a) + 1

end

function inOutBackInternal(t, a)

return t < 0.5 and 0.5 * inBackInternal(t * 2, a) or 0.5 + 0.5 * outBackInternal(t * 2 - 1, a)

end

function outInBackInternal(t, a)

return t < 0.5 and 0.5 * outBackInternal(t * 2, a) or 0.5 + 0.5 * inBackInternal(t * 2 - 1, a)

end



inBack = with1param(inBackInternal, 1.70158)

outBack = with1param(outBackInternal, 1.70158)

inOutBack = with1param(inOutBackInternal, 1.70158)

outInBack = with1param(outInBackInternal, 1.70158)

-- converts: nil to {1, 2}, number to {number} ({1, 2} if number is less than 1), and {...} to {...}
function getPlayers(players)
	local allPlayers = plr or allPlayers
	local players = players or allPlayers

	if type(players) == 'number' then
		if players <= 0 then
			players = allPlayers
		else
			players = {players}
		end
	end

	return players
end

local function getArr(t)
	return t and (type(t) == "table" and t or {t}) or {}
end

-- runs a func for each remapped (or not) mod for each player

local function queueFunc(mods, func, players, mult)
	players = getPlayers(players)
	mult = mult or 1

	for i=1,#mods,2 do
		local percent = mods[i]
		local mod = mods[i + 1]
		if type(percent) ~= 'number' or type(mod) ~= 'string' then
			error ('Mixed up bitch? '..tostring(percent)..', '..tostring(mod))
		end
		for _,player in pairs(players) do
			func(mod, percent * mult, player - 1)
		end
	end

end



function ease(params)
	-- get those vars
	local beat, len, ease_fn = unpack(params)
	if type(beat) ~= 'number' then
		error('[ease] Beat ['..tostring(beat)..'] not a number value')
	elseif type(len) ~= 'number' then
		error('[ease] Length ['..tostring(len)..'] not a numerb value')
	elseif type(ease_fn) ~= 'function' then
		error('[ease] Ease ['..tostring(ease_fn)..'] not a function value')
	end
	if params.mode == "end" then
		len = len - beat
	end
	-- remove them from the table
	for i=1,3 do table.remove(params, 1) end
	__hold_ease(ease_fn)
	queueFunc(params, function(mod, percent, player)
		__ease(beat, len, nil, percent, mod, player)
	end, params.plr)
end



function set(params)
	-- get the beat from the table and also remove it
	local beat = table.remove(params, 1)
	if type(beat) ~= 'number' then
		error('[set] Beat ['..tostring(beat)..'] not a number value')
	end
	queueFunc(params, function(mod, percent, player)
		__set(beat, percent, mod, player)
	end, params.plr)
end

function setdefault(params)
	queueFunc(params, __setdefault, params.plr)
end

function add(params)
	-- get the beat from the table and also remove it
	local beat = table.remove(params, 1)
	if type(params[2]) == "function" then -- its an add ease event (dumb way of detecting this but whatever)
		local len, ease_fn = unpack(params)
		for i=1,2 do table.remove(params, 1) end
		__hold_ease(ease_fn)
		queueFunc(params, function(mod, percent, player)
			__addease(beat, len, nil, percent, mod, player)
		end, params.plr)
	else
		queueFunc(params, function(mod, percent, player)
			__add(beat, percent, mod, player)
		end, params.plr)
	end
end

function reset(params)
	-- get those vars
	local beat, len, ease_fn = unpack(params)
	if type(beat) ~= 'number' then
		error('[ease] Beat ['..tostring(beat)..'] not a number value')
	elseif len and type(len) ~= 'number' then
		error('[ease] Length ['..tostring(len)..'] not a numerb value')
	elseif (len or ease_fn) and type(ease_fn) ~= 'function' then
		error('[ease] Ease ['..tostring(ease_fn)..'] not a function value')
	end
	if params.mode == "end" then
		len = len - beat
	end
	params.exclude = getArr(params.exclude)
	-- remove them from the table
	for i=1,3 do table.remove(params, 1) end
	if ease_fn then
		__hold_ease(ease_fn)
	end
	queueFunc(params, function(mod, percent, player)
		__reset(beat, len or .0, nil, params.exclude, player)
	end, params.plr)
end

function func(params)
	__hold_func(params[2])
	__func(params[1], nil)
end

function func_ease(params)
	local func = table.remove(params, #params)
	local beat = params[1]
	local len = params[2]
	local ease_fn = params[3]
	local begin_percent = params[4] or 0
	local end_percent = params[5] or 1
	__hold_ease(ease_fn)
	__hold_func(func)
	__func_ease(beat, len, nil, begin_percent, end_percent, nil)
end

function perframe(params)
	if type(params[3]) ~= 'function' then
		error('[perframe] Beat ['..tostring(beat)..'] not a number value')
	end
	__hold_func(function(b)
		params[3](b, poptions)
	end)
	__perframe(params[1], params[2], nil)
end

function alias(params)
	__alias(params[1], params[2])
end

function aux(params)
	for i=1,#params do
		__aux(params[i])
		__definemod_internal(params[i])
	end
end

function node(params)
	local args = {}
	while type(params[1]) == "string" do
		table.insert(args, table.remove(params, 1))
	end
	local func = table.remove(params, 1)
	if type(func) ~= "function" then
		error '[node] should be funtion i think'
	end
	local callback
	local _undo
	local _run
	-- then we are writing to mods
	if #params > 0 then
		local mods = params
		local values = {}
		callback = function(...)
			local arr = {...} -- store EVERYTHING
			local pn = arr[#arr] -- get player number (last argument after args) (there might be a better way to do this??) (there isnt)
			if _run then
				values[pn] = {func(...)}
			end
			for i,mod in ipairs(mods) do
				poptions[pn][mod] = _undo and poptions[pn][mod] - values[pn][i] or poptions[pn][mod] + values[pn][i]
			end
		end
	else
		callback = func
	end
	local _terminated = false
	local _values
	local _call = (not debug) and nil or function()
		callback(unpack(_values))
	end
	__hold_func(function(plr, undo, run)
		if _terminated then
			return
		end
		plr = plr + 1 -- whatever
		_undo = undo
		_run = run
		local values = {}
		for i=1,#args do
			values[i] = poptions[plr][args[i]]
		end
		values[#args + 1] = plr
		if debug then
			_values = values
			local s, r = pcall(_call)
			if not s then
				__log {"[NODE]", args, r}
				_terminated = true
			end
		else
			callback(unpack(values))
		end
	end)
	__node(args, nil)
end

function definemod(params)
	-- simple definemod (name, percent1, mod1, percent2, mod2, ...)
	if type(params[2]) == 'number' then
		local id = table.remove(params, 1)
		local percents = {}
		local mods = {}
		for i=1,#params,2 do
			table.insert(percents, params[i])
			table.insert(mods, params[i + 1])
		end
		__definemod(id, percents, mods)
		__definemod_internal(id) -- add it to poptions
	else
		local i = 1
		while type(params[i]) == "string" do
			aux {params[i]}
			i = i + 1
		end
		node(params)
	end
end

function use_percent(value)
	__use_percent = value
	__set_use_percent(value)
end


-- _G is apparently slow so put it in some nice thing
for _,mod in ipairs(__mods) do
	__definemod_internal(mod)
end

local function _wrap(func)
	return function(_, ...)
		return func(...)
	end
end

GAMESTATE = {}
for _,c in ipairs(__gamestate_callbacks) do
	local func = _G["__gamestate_"..c]
	--__log {tostring(_G["__gamestate_"..c])}
	GAMESTATE[c] = function(self, ...) return func(...) end
end

-- i forgot how cool metatables were
for plr=1,players do
	local function _bool(mod)
		return function(_, v)
			if __ran then
				__modFuncs[plr][mod].set(v and 1 or 0)
			else
				-- doesnt work :(
				__setdefault(mod, v and 1 or 0, plr)
				__log {"no run so here", v}
			end
		end
	end
	poptions[plr] = setmetatable({
		-- would check type at runtime but that might be slow??
		-- these work with both numbers and bools :)
		jimbleusetan = _bool "jimbleusetan",
		zbuffer = _bool "zbuffer",
		cosecant = _bool "cosecant",
		modtimertype = _wrap(_G["__setModTimerType-"..(plr - 1)]),
		resetall = _wrap(_G["__resetAll-"..(plr - 1)]),
	}, {
		__index = function(self, key)
			local v = rawget(self, key:lower())
			if v then
				return v
			end
			local v = __modFuncs[plr][key:lower()].get()
			if __use_percent and __modFuncs[plr][key:lower()].isPercent then
				v = v * 100
			end
			return v
		end,
		__newindex = function(self, key, value)
			if rawget(self, key:lower()) then error 'please dont do that' end
			if __use_percent and __modFuncs[plr][key:lower()].isPercent then
				value = value / 100
			end
			__modFuncs[plr][key:lower()].set(value)
		end
	})
end

function log(...)
	__log{...}
end

function get_plr()
	return getPlayers()
end

-- mod stuff
local toPercentRad = 100 * (math.pi / 180)
local function angleMod(angle, confusion)
	aux {'angle'..angle, 'angle'..angle..'0', 'angle'..angle..'1', 'angle'..angle..'2', 'angle'..angle..'3'}
	node {'angle'..angle, 'angle'..angle..'0', 'angle'..angle..'1', 'angle'..angle..'2', 'angle'..angle..'3',
		function(a, _0, _1, _2, _3)
			return a * toPercentRad, _0 * toPercentRad, _1 * toPercentRad, _2 * toPercentRad, _3 * toPercentRad
		end,
		'ConfusionOffset'..confusion, 'Confusion'..confusion..'Offset0', 'Confusion'..confusion..'Offset1', 'Confusion'..confusion..'Offset2', 'Confusion'..confusion..'Offset3'
	}
end
angleMod("", "")
--angleMod("x", "X")
--angleMod("y", "Y")

function SCALE(value, start1, stop1, start2, stop2)
	return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1))
end

-- plugin stuff
local _plugins = {}
function __add_plugin(func)
	func()
end

--function __update(e)
--	if update then
--		update()
--	end
--end
function confrad(d)
	return math.rad(d) * 100
end
end