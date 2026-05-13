--[[
Fishtank door navigation script v3  (updates are released here: https://kiwifarms.net/search/member?user_id=40045)
Check out the clipping script too - https://rentry.org/mpv-clip-lua-script

== INSTRUCTIONS ==

Put the lua file in mpv's scripts directory.

The default keybind is left mouse button, which may not work if another script binds it first.
If LMB doesn't work for you, add this line to input.conf to change it to right double click:
MBTN_RIGHT_DBL script-binding fishtank_doors/pick-door

== CHANGELOG ==
- update for s05
-- add cams
-- add polygons
-- properly escape cam titles
-- change side button offset
- v3 released (june 15 2025)
- grid mode removed because fishtank.live no longer provides a grid stream :(
- updated tables to use season 4 streams
- v2 released (Nov 8 2024)
- video margins are respected (doors don't stretch over the black bars when maximized on a non-16:9 monitor)
- overlay scale is now updated with window size
- added side buttons
- added grid mode
- added clickable zones on PTZ cams
]]--
local mp = require("mp")

local options = {
	hide_timeout_seconds = 0.7,
	door_font_height = 56,
	sidebtn_font_height = 38
}
require("mp.options").read_options(options)
local filename = nil

-- to generate this table:
-- curl 'https://api.fishtank.live/v1/live-streams/zones' -H 'Referer: https://www.fishtank.live/' | jq -r '.clickableZones | map(select(.action.name == "Change Live Stream")) | map("{room=\"" + .room + "\", to=\"" + .action.metadata + "\", points={" + (.points | split(" ") | join(",")) + "}}") | join(",\n")'
local doors = {
{room="foyr-5", to="bkny-5", points={0.3407,0.0071,0.4750,0.2720,0.5805,0.2530,0.5859,0.0285}},
{room="dmcl-5", to="dmrm-5", points={0.6854,0.0166,0.6273,0.5819,0.7248,0.6865,0.8317,0.1152}},
{room="cfsl-5", to="codr-5", points={0.1364,0.9976,0.1364,0.0012,0.0020,0.0024,0.0014,0.9976}},
{room="codr-5", to="cfsl-5", points={0.5517,0.6387,0.3545,0.9928,0.0020,0.9964,0.0007,0.0024,0.5436,0.0036}},
{room="codr-5", to="hwup-5", points={0.7435,0.2653,0.8346,0.3109,0.9224,0.3433,0.9353,0.2053,0.8535,0.0012,0.7752,0.0000,0.7455,0.0060}},
{room="gsrm-5", to="foyr-5", points={0.2553,0.5114,0.2357,0.2593,0.2222,0.0636,0.1134,0.1224,0.0358,0.1813,0.0675,0.4406,0.1053,0.6363}},
{room="gsrm-5", to="ktch-5", points={0.5672,0.3745,0.5780,0.2041,0.5895,0.0084,0.5760,0.0000,0.5281,0.0012,0.5112,0.3205}},
{room="jckz-5", to="dmrm-5", points={0.0844,0.0096,0.1067,0.2041,0.1351,0.3842,0.1452,0.4370,0.1074,0.4790,0.0797,0.5102,0.0439,0.3517,0.0081,0.1729,0.0007,0.1357,0.0000,0.0948}},
{room="brrr-5", to="brpz-5", points={0.8164,0.0024,0.8184,0.0852,0.7536,0.0864,0.7550,0.0000}},
{room="brrr-5", to="brrr2-5", points={0.3289,0.0636,0.2343,0.1008,0.2289,0.0036,0.3255,0.0036}},
{room="brrr-5", to="ktch-5", points={0.9717,0.2641,0.9082,0.2029,0.8799,0.3866,0.8535,0.5258,0.9082,0.5822}},
{room="brrr-5", to="hwdn-5", points={0.9987,0.3349,0.9542,0.5474,0.8887,0.7611,0.8029,0.9652,0.8002,0.9712,0.7914,0.9976,0.7907,0.9940,0.9987,0.9940}},
{room="bbcl-5", to="bkny-5", points={0.4626,0.0132,0.3815,0.0132,0.3815,0.3169,0.3876,0.4274,0.3863,0.4358,0.3890,0.4394,0.4599,0.3914}},
{room="jobb-5", to="bkny-5", points={0.8785,0.0024,0.8785,0.9952,0.8785,0.9952,0.9967,0.9940,0.9981,0.0036}},
{room="jobb-5", to="hwup-5", points={0.1276,0.9976,0.1276,0.0000,0.1276,0.0000,0.0014,0.0012,0.0014,0.9976}},
{room="bare-5", to="bkny-5", points={0.5368,0.2641,0.5497,0.0024,0.4943,0.0024,0.4875,0.2953}},
{room="br4j-5", to="hwup-5", points={0.4869,0.3830,0.4923,0.0144,0.4227,0.0228,0.4214,0.1813,0.4220,0.4298}},
{room="mrke2-5", to="foyr-5", points={0.2512,0.1345,0.4356,0.0720,0.4369,0.4826,0.3640,0.5378,0.3181,0.5738,0.2971,0.5870,0.2816,0.6026}},
{room="mrke2-5", to="mrke-5", points={0.5868,0.0000,0.5814,0.1357,0.7509,0.1609,0.7597,0.0024}},
{room="mrke2-5", to="dmrm2-5", points={0.9995,0.4858,0.9989,0.9978,0.9922,0.9906,0.8358,0.9954,0.9301,0.7744,0.9715,0.6129}},
{room="mrke-5", to="foyr-5", points={0.9981,0.2509,0.9461,0.1825,0.8617,0.7239,0.8806,0.9928,0.9069,0.9976,0.9981,0.7119}},
{room="mrke-5", to="mrke2-5", points={0.3559,0.0024,0.3579,0.1068,0.5085,0.1092,0.5098,0.0012}},
{room="mrke-5", to="dmrm2-5", points={0.3601,0.1188,0.4182,0.1199,0.4343,0.4110,0.3775,0.4573}},
{room="dmrm2-5", to="dmrm-5", points={0.5254,0.0024,0.5254,0.0684,0.6213,0.0684,0.6213,0.0036}},
{room="dmrm2-5", to="hwdn-5", points={0.9785,0.6915,0.9832,0.3637,0.7989,0.9952,0.8671,0.9964}},
{room="dmrm2-5", to="mrke2-5", points={0.9955,0.7293,0.8766,0.9978,0.9982,0.9942}},
{room="dmrm2-5", to="jckz-5", points={0.0200,0.0902,-0.0007,0.1259,0.0862,0.6390,0.1476,0.4692,0.0902,0.0404}},
{room="dmrm-5", to="jckz-5", points={0.9064,0.1275,0.9708,0.1740,0.9366,0.4577,0.8756,0.4184}},
{room="dmrm-5", to="dmcl-5", points={0.1810,0.1097,0.1053,0.1573,0.1562,0.5352,0.2172,0.4827}},
{room="dmrm-5", to="hwdn-5", points={0.5223,0.0012,0.5095,0.0012,0.4633,0.0083,0.4660,0.1871,0.4733,0.3051,0.5236,0.2789}},
{room="dmrm-5", to="mrke2-5", points={0.5766,0.2396,0.5410,0.2634,0.5431,0.0262,0.5437,0.0024,0.5437,0.0012,0.5444,0.0024,0.5773,0.0012,0.5793,0.0012}},
{room="dmrm-5", to="dmrm2-5", points={0.6369,0.1001,0.5819,0.0799,0.5813,0.0036,0.6363,0.0012}},
{room="dnrm-5", to="hwup-5", points={0.2006,0.0036,0.0014,0.0036,0.0007,0.2761,0.0000,0.3397,0.0115,0.4226,0.0257,0.4994,0.0358,0.5534,0.0513,0.6387,0.0527,0.6399,0.0939,0.6062,0.1310,0.5798,0.1486,0.5666,0.1533,0.5366,0.1722,0.4874,0.1918,0.4346,0.2107,0.3733,0.2282,0.3289,0.2289,0.2977,0.2093,0.3073}},
{room="dnrm-5", to="ktch-5", points={0.6415,0.3505,0.6550,0.1909,0.6692,0.0024,0.8009,0.0012,0.9157,0.0624,0.9164,0.0864,0.9076,0.1753,0.8914,0.3049,0.8569,0.4970,0.8563,0.5006,0.8549,0.5042,0.8535,0.5150}},
{room="br3g-5", to="hwup-5", points={0.1971,0.4744,0.1515,0.0298,0.0550,0.0942,0.1146,0.5459}},
{room="hwup-5", to="codr-5", points={0.5227,0.3409,0.5206,0.0300,0.5774,0.0372,0.5726,0.3469}},
{room="hwup-5", to="bkny-5", points={0.6159,0.7851,0.4079,0.7863,0.3869,0.9976,0.6334,0.9964}},
{room="hwup-5", to="br4j-5", points={0.5861,0.5078,0.5922,0.0384,0.6145,0.0540,0.6064,0.4070,0.5936,0.5954}},
{room="hwup-5", to="dnrm-5", points={0.5011,0.3397,0.5004,0.2017,0.4551,0.2041,0.4558,0.2353,0.4443,0.2881,0.4450,0.3397}},
{room="hwup-5", to="br3g-5", points={0.4425,0.5089,0.4324,0.0453,0.4096,0.0608,0.4311,0.5995}},
{room="computer-lab2-5", to="bkny-5", points={0.4532,0.0310,0.3882,0.0286,0.3949,0.4672,0.4546,0.4172}},
{room="brrr2-5", to="ktch-5", points={0.3079,0.0048,0.3167,0.1741,0.3282,0.3397,0.3741,0.3397,0.3896,0.3037,0.3768,0.3025,0.3640,0.0348,0.3626,0.0000}},
{room="brrr2-5", to="hwdn-5", points={0.4734,0.2965,0.6186,0.3001,0.6186,0.2473,0.5639,0.2461,0.5314,0.2497,0.4767,0.2509,0.4734,0.2497}},
{room="brrr2-5", to="foyr-5", points={0.6206,0.0240,0.5612,0.0204,0.5618,0.2449,0.6172,0.2461}},
{room="brrr2-5", to="brpz-5", points={0.2789,0.1080,0.2262,0.1501,0.2141,0.0024,0.2721,0.0036}},
{room="brrr2-5", to="bar-5", points={0.8272,0.4418,0.8421,0.3001,0.8448,0.2905,0.8542,0.2881,0.8556,0.2725,0.8481,0.2665,0.8427,0.2581,0.8515,0.0024,0.6348,0.0012,0.6314,0.1705,0.6388,0.2173,0.6483,0.2341,0.6483,0.3325,0.6753,0.4346}},
{room="bar-5", to="brrr2-5", points={0.2024,0.1045,0.3875,0.1069,0.3842,0.0035,0.2158,0.0023,0.2044,-0.0000}},
{room="bar-5", to="brpz-5", points={0.7329,0.0023,0.7283,0.0784,0.8252,0.1045,0.8245,0.0023}},
{room="bar-5", to="ktch-5", points={0.9220,0.5856,0.9548,0.4312,0.9802,0.2577,0.9020,0.1865,0.8846,0.3551,0.8505,0.5191,0.9167,0.6010}},
{room="bar-5", to="hwdn-5", points={0.8619,0.7792,0.9995,0.3041,0.9989,0.9954,0.7857,0.9978}},
{room="bar-5", to="dnrm-5", points={0.8385,0.0380,0.8258,0.1615,0.8793,0.2126,0.8966,0.0760}},
{room="bkny-5", to="hwup-5", points={0.3322,0.9988,0.3721,0.7695,0.6071,0.8067,0.6091,0.8992,0.5996,0.9184,0.6044,0.9976}},
{room="bkny-5", to="mrke-5", points={0.2829,0.4910,0.0716,0.4778,0.0736,0.4802,0.1283,0.7407,0.1513,0.8319,0.2087,0.8487,0.2141,0.8271,0.2046,0.8019,0.2188,0.7515,0.2100,0.7215,0.2255,0.6819,0.2195,0.6435}},
{room="bkny-5", to="foyr-5", points={0.1519,0.8283,0.1148,0.9448,0.0419,0.7347,0.0020,0.8475,0.0007,0.9976,0.2019,0.9988,0.2114,0.9796,0.1992,0.9520,0.2120,0.9076,0.2033,0.8752,0.2080,0.8535}},
{room="bkny-5", to="bare-5", points={0.5639,0.3770,0.5740,0.0024,0.5733,0.0084,0.4686,0.0012,0.4720,0.3721}},
{room="bkny-5", to="computer-lab2-5", points={0.4274,0.0120,0.4524,0.0060,0.4565,0.2377,0.4612,0.3782,0.4416,0.4850,0.4396,0.4874,0.4383,0.4910}},
{room="bkny-5", to="brrr2-5", points={0.6618,0.3049,0.6523,0.1104,0.6138,0.0588,0.6057,0.1333,0.5990,0.3709,0.5936,0.5726,0.6003,0.6987,0.6064,0.7863,0.6111,0.8944,0.6368,0.6375}},
{room="hwdn-5", to="foyr-5", points={0.2782,0.8800,0.2445,0.6267,0.2228,0.3553,0.2201,0.2221,0.1695,0.3433,0.1310,0.4526,0.1742,0.7479,0.2235,0.9640,0.2336,0.9952,0.2620,0.9952}},
{room="hwdn-5", to="dmrm-5", points={0.4099,0.3193,0.4193,0.0144,0.3356,0.0156,0.3316,0.3157}},
{room="hwdn-5", to="brrr2-5", points={0.8191,0.9988,0.6901,0.6279,0.5753,0.3373,0.5490,0.2713,0.5328,0.4766,0.5119,0.7107,0.4923,0.9328,0.5038,0.9988}},
{room="ktch-5", to="dnrm-5", points={0.4295,0.4934,0.3140,0.5582,0.1877,0.6351,0.0993,0.6867,0.1020,0.6879,0.0493,0.4526,0.0223,0.2545,0.0101,0.0480,0.0020,0.0564,0.0014,0.0012,0.2883,0.0012,0.4234,0.0000,0.4322,0.0000}},
{room="ktch-5", to="gsrm-5", points={0.9798,0.2293,0.9994,0.2497,0.9987,0.3601,0.9987,0.4958,0.9717,0.6242,0.9697,0.6267,0.9326,0.5822,0.9272,0.6002,0.9191,0.5918,0.9116,0.5822}},
{room="ktch-5", to="brrr2-5", points={0.7057,0.9976,0.8373,0.7575,0.8590,0.7803,0.9278,0.6002,0.9332,0.5846,0.9731,0.6291,0.9974,0.5042,0.9987,0.9952}},
{room="brpz-5", to="bar-5", points={0.9987,0.9160,0.0014,0.9160,0.0014,0.9988,0.5375,0.9988,0.9947,0.9988,0.9987,0.9976}},
{room="brpz-5", to="brrr2-5", points={0.9979,0.1206,0.9979,0.1206,0.0017,0.1089,0.0017,0.0052,0.9973,0.0052}},
{room="foyr-5", to="bkny-5", points={0.3093,0.0036,0.4686,0.2881,0.5747,0.2569,0.6077,0.1068,0.6226,0.0012}},
{room="foyr-5", to="mrke-5", points={0.1148,0.8247,0.0338,0.2809,0.0358,0.0060,0.0014,0.0060,0.0027,0.9952,0.1546,0.9988}},
{room="foyr-5", to="hwdn-5", points={0.1681,0.3097,0.0682,0.3589,0.0864,0.5138,0.1749,0.4682}},
{room="foyr-5", to="gsrm-5", points={0.7597,0.7599,0.8819,0.4094,0.7286,0.2293,0.6375,0.5846}},
{room="foyr-5", to="brrr2-5", points={0.1762,0.0504,0.0594,0.0924,0.0696,0.3529,0.1702,0.3097}}
}

-- calculate aabb and average for every door
for i=1, #doors do
	local points = doors[i].points
	local x1, y1, x2, y2 = points[1], points[2], points[1], points[2]
	local sum_x, sum_y = 0, 0
	local n_points = #points/2
	for i=1,n_points do
		local x, y = points[i*2-1], points[i*2]
		sum_x = sum_x + x
		sum_y = sum_y + y
		x1, y1 = math.min(x1, x), math.min(y1, y)
		x2, y2 = math.max(x2, x), math.max(y2, y)
	end
	doors[i].avg_x = sum_x / n_points
	doors[i].avg_y = sum_y / n_points
	doors[i].aabb = {x1, y1, x2, y2}
end

-- command to generate:
--curl 'https://api.fishtank.live/v1/live-streams' -H 'Referer: https://www.fishtank.live/' | jq -r '.liveStreams | map("[\"" + .id + "\"]=\"" + .name + "\"") | join(",\n")'
local room_titles = {
["jet-5"]="jetnep",
["dirc-5"]="Director Mode",
["laura-5"]="Laura",
["damiel-5"]="Damiel",
["ben-5"]="bendub",
["dmrm-5"]="Dorm",
["dmrm2-5"]="Dorm Alternate",
["dmcl-5"]="Closet",
["bar-5"]="Bar",
["brrr2-5"]="Bar Alternate",
["ktch-5"]="Kitchen",
["cameraman2-5"]="Cameraman",
["hwdn-5"]="Hallway Down",
["jckz-5"]="Jacuzzi",
["brpz-5"]="Bar PTZ",
["dnrm-5"]="Dining Room",
["mrke-5"]="Market",
["mrke2-5"]="Market Alternate",
["foyr-5"]="Foyer",
["gsrm-5"]="Glassroom",
["computer-lab2-5"]="Bedroom 2 (Computer Lab)",
["bare-5"]="Bedroom 1 (Arena)",
["cfsl-5"]="Confessional",
["codr-5"]="Corridor",
["hwup-5"]="Hallway Up (West Wing)",
["bkny-5"]="Balcony (East Wing)",
["jobb-5"]="Job Board",
["br3g-5"]="Bedroom 3 (Goo Room)",
["br4j-5"]="Bedroom 4 (Jungle Room)"
}
local DIRECTOR_BTN = "dirc-5"

local BACK_BTN = "_BACK"

local PTZ_BTN = "_PTZ"
local side_buttons = {DIRECTOR_BTN, BACK_BTN} -- you can put room ids here like "director-mode-3"

local function points_to_ass_path(points, x_mult, y_mult, x_off, y_off)
	local path = "m " .. points[1]*x_mult + x_off .. " " .. points[2]*y_mult + y_off .. " l"
	for i=3,#points,2 do
		path = path .. " " .. points[i]*x_mult + x_off .. " " .. points[i+1]*y_mult + y_off
	end
	return path
end

local function point_in_polygon(x, y, path)
	local inside = false
	local n = #path/2

	for i=0,n-1 do
		local x1, y1 = path[i*2+1], path[i*2+2]
		local x2, y2 = path[((i+1) % n)*2+1], path[((i+1) % n)*2+2]

		-- check if the point is within the y range of the segment
		if ((y1 > y) ~= (y2 > y)) then
			 -- calculate the x coordinate of the intersection
			local intersectX = (x2 - x1) * (y - y1) / (y2 - y1) + x1
			if x < intersectX then
				inside = not inside
			end
		end
	end

	return inside
end

local HOV_TYPE_DOOR = 2
local HOV_TYPE_SIDEBTN = 3

-- STATE
local ass = nil
local current_room = nil
local previous_room = nil
local hovered_type = HOV_TYPE_DOOR
local hovered_door_i = 0 -- 0 always means nothing is hovered
local mouse_x, mouse_y = 0, 0
local last_mousemove_t = 0

local is_visible = false

local dim = mp.get_property_native("osd-dimensions")
dim.vw, dim.vh = 1, 1

local function make_door_ass(points, aabb, is_hovered, label, white_label)
	local text = "{\\shad0\\an7\\pos(0, 0)\\1c&H2020ff&"
	if is_hovered then
		text = text .. "\\bord0\\1a&Hd0&"
	else
		text = text .. "\\bord4\\1a&Hff&\\3a&Hbb&\\3c&H2020ff&"
	end
	text = text .. "\\p1}" .. points_to_ass_path(points, dim.vw, dim.vh, dim.ml, dim.mt) .. "{\\p0}\n"

	if label then
		local mid_x = (aabb[1] + aabb[3]) / 2
		local mid_y = (aabb[2] + aabb[4]) / 2
		local x, y = dim.ml + mid_x*dim.vw, dim.mt + mid_y*dim.vh
		local fs = math.max(dim.vh, 480) / 1080 * options.door_font_height -- fs = door_font_height @ 1080p, shrinks with player size until 480p
		text = text .. "{\\shad0\\bord0\\fs".. fs .."\\an5\\pos(".. x ..", ".. y ..")\\1c&H".. (white_label and "ffffff" or "000050") .."&\\1a&H00&}".. label .."\n"
	end
	return text
end

local function redraw()
	if ass == nil then return end
	ass.res_x = dim.w
	ass.res_y = dim.h
	--print("redrawing")
	ass.data = ""
	if is_visible then
		for i=1,#doors do
			if doors[i].room == current_room then
				local is_hovered = i == hovered_door_i and hovered_type == HOV_TYPE_DOOR
				ass.data = ass.data .. make_door_ass(doors[i].points, doors[i].aabb, is_hovered, is_hovered and room_titles[doors[i].to])
			end
		end
		local top_offset = options.sidebtn_font_height/2 + 60
		for i=1,#side_buttons do
			local btn = side_buttons[i]
			local label
			if btn == BACK_BTN then
				label = "Prev"
			else
				label = room_titles[btn]
			end
			local is_hovered = i == hovered_door_i and hovered_type == HOV_TYPE_SIDEBTN
			if is_hovered then
				ass.data = ass.data .. "{\\shad0\\bord1\\fs"..options.sidebtn_font_height.."\\an6\\pos(".. dim.w-15 ..", "..top_offset..")\\1c&H2020ff&\\1a&H00&\\3c&H000005&\\3a&H80&}> "..label.."\n"
			else
				ass.data = ass.data .. "{\\shad0\\bord0\\fs"..options.sidebtn_font_height.."\\an6\\pos(".. dim.w-10 ..", "..top_offset..")\\1c&H000050&\\1a&H00&}"..label.."\n"
			end
			top_offset = top_offset + options.sidebtn_font_height
		end
	end
	ass:update()
end

local function update(force_redraw)
	if current_room == nil then return end
	local new_hov_type = 0
	local new_hovered = 0
	local top_offset = options.sidebtn_font_height/2 + 60
	for i=1,#side_buttons do
		if mouse_x > dim.w - options.sidebtn_font_height*2
		and mouse_y > top_offset - options.sidebtn_font_height/2
		and mouse_y < top_offset + options.sidebtn_font_height/2 then
			new_hovered = i
			new_hov_type = HOV_TYPE_SIDEBTN
			break
		end
		top_offset = top_offset + options.sidebtn_font_height
	end
	if new_hovered == 0 then
		for i=1,#doors do
			if doors[i].room == current_room then
				local x, y = (mouse_x-dim.ml)/dim.vw, (mouse_y-dim.mt)/dim.vh
				local aabb = doors[i].aabb
				if x >= aabb[1] and x <= aabb[3] and y >= aabb[2] and y <= aabb[4]
				and point_in_polygon(x, y, doors[i].points) then
					new_hovered = i
					new_hov_type = HOV_TYPE_DOOR
					break
				end
			end
		end
	end

	local new_is_visible = last_mousemove_t + options.hide_timeout_seconds > mp.get_time()
	if new_hovered ~= hovered_door_i or new_is_visible ~= is_visible or new_hov_type ~= hovered_type or force_redraw then
		hovered_type = new_hov_type
		hovered_door_i = new_hovered
		is_visible = new_is_visible
		redraw()
	end
end
local timer = mp.add_periodic_timer(0.1, update)

local _previous_hover = false
-- there is a bug in mpv where hover will stay false even after the pointer has moved back in
-- so we only hide on the first unhover
local function on_mouse_move(_, pos)
	--print(pos.x, pos.y, pos.hover)
	mouse_x, mouse_y = pos.x, pos.y
	if not pos.hover and _previous_hover then
		last_mousemove_t = 0 -- hide
	else
		last_mousemove_t = mp.get_time()
	end
	update()
	_previous_hover = pos.hover
end
mp.observe_property("mouse-pos", "native", on_mouse_move)

local function on_resize(_, dimensions)
	dim = dimensions
	dim.vw, dim.vh = dim.w-dim.ml-dim.mr, dim.h-dim.mt-dim.mb
	update(true)
end
mp.observe_property("osd-dimensions", "native", on_resize)

local function switch_cam_by_title(title)
	local title_escaped = string.gsub(title, "%p", "%%%1")
	local playlist = mp.get_property_native("playlist")
	for i=1,#playlist do
		if playlist[i].title:find(title_escaped.."$") then
			mp.set_property_number("playlist-pos-1", i)
			return true
		end
	end
	return false
end

local function on_click()
	last_mousemove_t = mp.get_time()
	if current_room == nil or hovered_door_i == 0 then return end
	local door_id
	if hovered_type == HOV_TYPE_SIDEBTN then
		door_id = side_buttons[hovered_door_i]
		if door_id == BACK_BTN then
			door_id = previous_room
		end
	elseif hovered_type == HOV_TYPE_DOOR then
		door_id = doors[hovered_door_i].to
	end
	if not door_id then return end
	switch_cam_by_title(room_titles[door_id])
end
mp.add_key_binding("mbtn_left", "pick-door", on_click)

local function file_loaded()
	if not filename:find("%.m3u") then return end
	local title = mp.get_property("media-title")
	--if title:find("PTZ$") then return end

	-- match room id
	for r_id,r_title in pairs(room_titles) do
		local r_title_escaped = string.gsub(r_title, "%p", "%%%1")
		if title:find(r_title_escaped.."$") then
			current_room = r_id
			ass = mp.create_osd_overlay("ass-events")
			ass.res_x = w
			ass.res_y = h
			update()
			break
		end
	end
end

local function end_file()
	previous_room = current_room
	current_room = nil
	hovered_type = HOV_TYPE_DOOR
	hovered_door_i = 0
	is_visible = false
	if ass then
		ass:remove()
	end
end

local function on_load()
	if filename  == nil then filename = mp.get_property("playlist/0/filename") end -- hopefully filename doesn't include query strings
end

mp.add_hook("on_load", 50, on_load)
mp.register_event("file-loaded", file_loaded)
mp.register_event("end-file", end_file)
