protomonbattle_element_damage = {
	["fire"] = {
		["fire"] = 0.5,
		["air"] = 2,
		["life"] = 2,
		["water"] = 0.5,
		["earth"] = 0.5,
	},
	["air"] = {
		["fire"] = 0.5,
		["air"] = 0.5,
		["life"] = 2,
		["water"] = 2,
		["earth"] = 0.5,
	},
	["life"] = {
		["fire"] = 0.5,
		["air"] = 0.5,
		["life"] = 0.5,
		["water"] = 2,
		["earth"] = 2,
	},
	["water"] = {
		["fire"] = 2,
		["air"] = 0.5,
		["life"] = 0.5,
		["water"] = 0.5,
		["earth"] = 2,
	},
	["earth"] = {
		["fire"] = 2,
		["air"] = 2,
		["life"] = 0.5,
		["water"] = 0.5,
		["earth"] = 0.5,
	},
	["normal"] = {
		["fire"] = 1,
		["air"] = 1,
		["life"] = 1,
		["water"] = 1,
		["earth"] = 1,
	},
}

protomonbattle_attacks = {
	["inferno"] = {
		name = "Inferno",
		animation = "inferno",
		element = "fire",
		damage = 12,
	},
	["lightning bolt"] = {
		name = "Lightning Bolt",
		animation = "lightning bolt",
		element = "air",
		damage = 12,
	},
	["vine whip"] = {
		name = "Vine Whip",
		animation = "vine whip",
		element = "life",
		damage = 12,
	},
	["torrent"] = {
		name = "Torrent",
		animation = "torrent",
		element = "water",
		damage = 12,
	},
	["earth smash"] = {
		name = "Earth Smash",
		animation = "earth smash",
		element = "earth",
		damage = 12,
	},
	["hot foot"] = {
		name = "Hot Foot",
		animation = "hot foot",
		element = "fire",
		damage = 8,
	},
	["zap"] = {
		name = "Zap",
		animation = "zap",
		element = "air",
		damage = 8,
	},
	["overgrowth"] = {
		name = "Overgrowth",
		animation = "overgrowth",
		element = "life",
		damage = 8,
	},
	["splash"] = {
		name = "Splash",
		animation = "splash",
		element = "water",
		damage = 8,
	},
	["rock toss"] = {
		name = "Rock Toss",
		animation = "rock toss",
		element = "earth",
		damage = 8,
	},
	["flash fire"] = {
		name = "Flash Fire",
		animation = "flash fire",
		element = "fire",
		damage = 10,
	},
	["hot steam"] = {
		name = "Hot Steam",
		animation = "hot steam",
		element = "fire",
		damage = 10,
	},
	["bio shock"] = {
		name = "Bio Shock",
		animation = "bio shock",
		element = "air",
		damage = 10,
	},
	["static shock"] = {
		name = "Static Shock",
		animation = "static shock",
		element = "air",
		damage = 10,
	},
	["explosive egg"] = {
		name = "Explosive Egg",
		animation = "explosive egg",
		element = "life",
		damage = 10,
	},
	["kelp growth"] = {
		name = "Kelp Growth",
		animation = "kelp growth",
		element = "life",
		damage = 10,
	},
	["mist spray"] = {
		name = "Mist Spray",
		animation = "mist spray",
		element = "water",
		damage = 10,
	},
	["mud bath"] = {
		name = "Mud Bath",
		animation = "mud bath",
		element = "water",
		damage = 10,
	},
	["sand kick"] = {
		name = "Sand Kick",
		animation = "sand kick",
		element = "earth",
		damage = 10,
	},
	["rock slide"] = {
		name = "Rock Slide",
		animation = "rock slide",
		element = "earth",
		damage = 10,
	},
	["ram"] = {
		name = "Ram",
		animation = "tackle",
		element = "normal",
		damage = 8,
	},
	["tackle"] = {
		name = "Tackle",
		animation = "tackle",
		element = "normal",
		damage = 6,
		skipswapattack = true,
	},
	["fusion beam"] = {
		name = "Fusion Beam",
		animation = "fusion beam",
		element = "normal",
		damage = 20,
		recoverifnoko = true,
	},
}

protomonbattle_protomon = {
	[1] = {
		name = "Charenok",
		element = "fire",
		hp = 60,
		placement = {
			X = 11.0009765625,
			Y = 14.861450195313,
			Z = -0.000244140625,
			P = -0.28000009059906,
			R = -0.22999945282936,
			Yaw = 90.000022888184,
			S = 0.54999989271164,
			N = "Ravenok (Grey)",
			C = 17
		},
		flag = {
			N = "Fire Banner (Pell)",
			C = 17,
		},
		switchattack = "hot foot",
		attacks = {
			["inferno"] = true,
			["hot foot"] = true,
			["ram"] = true,
		},
		bonuses = {
			[1] = {
				cost = 1,
				addons = {attacks = {["tackle"] = true}},
				description = "tackle (6, counter swap)",
				descriptioncolor = "normal",
			},
			[2] = {
				cost = 1,
				addons = {attacks = {["fusion beam"] = true}},
				description = "fusion beam (20, lose turn if no ko)",
				descriptioncolor = "normal",
			},
			[3] = {
				cost = 1,
				addons = {hp = 70},
				description = "70 health",
				descriptioncolor = "normal",
			},
			[4] = {
				cost = 1,
				addons = {attacks = {["sand kick"] = true}},
				description = "sand kick (10)",
				descriptioncolor = "earth",
			},
			[5] = {
				cost = 2,
				addons = {attacks = {["explosive egg"] = true}},
				description = "explosive egg (10)",
				descriptioncolor = "life",
			},
			[6] = {
				cost = 2,
				addons = {switchattack = "inferno"},
				description = "swap: inferno (12)",
				descriptioncolor = "fire",
			},
		},
	},
	[2] = {
		name = "Vindchu",
		element = "air",
		hp = 60,
		placement = {
			X = 11.752197265625,
			Y = 14.861267089844,
			Z = -0.00341796875,
			P = -0.27999991178513,
			R = -0.22999891638756,
			Yaw = 90.000022888184,
			S = 0.99999922513962,
			N = "Vind"
		},
		flag = {
			N = "Wind Banner (Pell)",
			C = 2,
		},
		switchattack = "zap",
		attacks = {
			["lightning bolt"] = true,
			["zap"] = true,
			["ram"] = true,
		},
		bonuses = {
			[1] = {
				cost = 1,
				addons = {attacks = {["tackle"] = true}},
				description = "tackle (6, counter swap)",
				descriptioncolor = "normal",
			},
			[2] = {
				cost = 1,
				addons = {attacks = {["fusion beam"] = true}},
				description = "fusion beam (20, lose turn if no ko)",
				descriptioncolor = "normal",
			},
			[3] = {
				cost = 1,
				addons = {hp = 70},
				description = "70 health",
				descriptioncolor = "normal",
			},
			[4] = {
				cost = 1,
				addons = {attacks = {["flash fire"] = true}},
				description = "flash fire (10)",
				descriptioncolor = "fire",
			},
			[5] = {
				cost = 2,
				addons = {attacks = {["mist spray"] = true}},
				description = "mist spray (10)",
				descriptioncolor = "water",
			},
			[6] = {
				cost = 2,
				addons = {switchattack = "lightning bolt"},
				description = "swap: lightning bolt (12)",
				descriptioncolor = "air",
			},
		},
	},
	[3] = {
		name = "Stemasaur",
		element = "life",
		hp = 60,
		placement = {
			X = 11.689208984375,
			Y = 14.819946289063,
			Z = 0.000244140625,
			P = 0.3000003695488,
			R = 0.21000035107136,
			Yaw = 90.000022888184,
			S = 0.29999992251396,
			N = "Stemdragon (Green)"
		},
		flag = {
			N = "Banner (Life, Pell)",
			C = 7,
		},
		switchattack = "overgrowth",
		attacks = {
			["vine whip"] = true,
			["overgrowth"] = true,
			["ram"] = true,
		},
		bonuses = {
			[1] = {
				cost = 1,
				addons = {attacks = {["tackle"] = true}},
				description = "tackle (6, counter swap)",
				descriptioncolor = "normal",
			},
			[2] = {
				cost = 1,
				addons = {attacks = {["fusion beam"] = true}},
				description = "fusion beam (20, lose turn if no ko)",
				descriptioncolor = "normal",
			},
			[3] = {
				cost = 1,
				addons = {hp = 70},
				description = "70 health",
				descriptioncolor = "normal",
			},
			[4] = {
				cost = 1,
				addons = {attacks = {["bio shock"] = true}},
				description = "bio shock (10)",
				descriptioncolor = "air",
			},
			[5] = {
				cost = 2,
				addons = {attacks = {["rock slide"] = true}},
				description = "rock slide (10)",
				descriptioncolor = "earth",
			},
			[6] = {
				cost = 2,
				addons = {switchattack = "vine whip"},
				description = "swap: vine whip (12)",
				descriptioncolor = "life",
			},
		},
	},
	[4] = {
		name = "Squig",
		element = "water",
		hp = 60,
		placement = {
			X = 11.751953125,
			Y = 14.861267089844,
			Z = -0.0030517578125,
			P = -0.27999991178513,
			R = -0.22999900579453,
			Yaw = 90.000022888184,
			S = 0.99999940395355,
			N = "Alien Skug",
			C = 11
		},
		flag = {
			N = "Water Banner (Pell)",
			C = 11,
		},
		switchattack = "splash",
		attacks = {
			["torrent"] = true,
			["splash"] = true,
			["ram"] = true,
		},
		bonuses = {
			[1] = {
				cost = 1,
				addons = {attacks = {["tackle"] = true}},
				description = "tackle (6, counter swap)",
				descriptioncolor = "normal",
			},
			[2] = {
				cost = 1,
				addons = {attacks = {["fusion beam"] = true}},
				description = "fusion beam (20, lose turn if no ko)",
				descriptioncolor = "normal",
			},
			[3] = {
				cost = 1,
				addons = {hp = 70},
				description = "70 health",
				descriptioncolor = "normal",
			},
			[4] = {
				cost = 1,
				addons = {attacks = {["kelp growth"] = true}},
				description = "kelp growth (10)",
				descriptioncolor = "life",
			},
			[5] = {
				cost = 2,
				addons = {attacks = {["hot steam"] = true}},
				description = "hot steam (10)",
				descriptioncolor = "fire",
			},
			[6] = {
				cost = 2,
				addons = {switchattack = "torrent"},
				description = "swap: torrent (12)",
				descriptioncolor = "water",
			},
		},
	},
	[5] = {
		name = "Boulderdude",
		element = "earth",
		hp = 60,
		placement = {
			X = 11.686889648438,
			Y = 14.818603515625,
			Z = 0.0028076171875,
			P = 0.30000019073486,
			R = 0.21000047028065,
			Yaw = 90.000045776367,
			S = 0.4499998986721,
			N = "Rime-Scaled Boulderback",
			C = 4
		},
		flag = {
			N = "Earth Banner (Pell)",
			C = 4,
		},
		switchattack = "rock toss",
		attacks = {
			["earth smash"] = true,
			["rock toss"] = true,
			["ram"] = true,
		},
		bonuses = {
			[1] = {
				cost = 1,
				addons = {attacks = {["tackle"] = true}},
				description = "tackle (6, counter swap)",
				descriptioncolor = "normal",
			},
			[2] = {
				cost = 1,
				addons = {attacks = {["fusion beam"] = true}},
				description = "fusion beam (20, lose turn if no ko)",
				descriptioncolor = "normal",
			},
			[3] = {
				cost = 1,
				addons = {hp = 70},
				description = "70 health",
				descriptioncolor = "normal",
			},
			[4] = {
				cost = 1,
				addons = {attacks = {["mud bath"] = true}},
				description = "mud bath (10)",
				descriptioncolor = "water",
			},
			[5] = {
				cost = 2,
				addons = {attacks = {["static shock"] = true}},
				description = "static shock (10)",
				descriptioncolor = "air",
			},
			[6] = {
				cost = 2,
				addons = {switchattack = "earth smash"},
				description = "swap: earth smash (12)",
				descriptioncolor = "earth",
			},
		},
	},
}

protomonbattle_names = {
	["charenok"] = 1,
	["vindchu"] = 2,
	["stemasaur"] = 3,
	["squig"] = 4,
	["boulderdude"] = 5,
}

protomonbattle_zones = {
	["housing"] = {
		center = {
			x = 1485,
			y = -700,
			z = 1440,
		},
	},
	[51006005] = { -- celestion
		center = {
			x = 2150,
			y = -900,
			z = -2350,
		},
	},
	[51006017] = { -- algoroc
		center = {
			x = 3650,
			y = -900,
			z = -4175,
		},
	},
	[51006014] = { -- thayd
		center = {
			x = 3975,
			y = -900,
			z = -2100,
		},
	},
	[51006016] = { -- galeras
		center = {
			x = 5650,
			y = -900,
			z = -2300,
		},
	},
	[22008007] = { -- ellevar
		center = {
			x = -2300,
			y = -900,
			z = -3500,
		},
	},
	[22008015] = { -- deradune
		center = {
			x = -5100,
			y = -900,
			z = -3500,
		},
	},
	[22008078] = { -- illium
		center = {
			x = -3225,
			y = -900,
			z = -950,
		},
	},
	[0104548] = { -- Redmoon Terror
		center = {
			x = -300,
			y = 750,
			z = -200,
		},
	},
}
