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
		name = "inferno",
		animation = "inferno",
		element = "fire",
		damage = 12,
	},
	["lightning bolt"] = {
		name = "lightning bolt",
		animation = "lightning bolt",
		element = "air",
		damage = 12,
	},
	["vine whip"] = {
		name = "vine whip",
		animation = "vine whip",
		element = "life",
		damage = 12,
	},
	["torrent"] = {
		name = "torrent",
		animation = "torrent",
		element = "water",
		damage = 12,
	},
	["earth smash"] = {
		name = "earth smash",
		animation = "earth smash",
		element = "earth",
		damage = 12,
	},
	["hot foot"] = {
		name = "hot foot",
		animation = "hot foot",
		element = "fire",
		damage = 8,
	},
	["zap"] = {
		name = "zap",
		animation = "zap",
		element = "air",
		damage = 8,
	},
	["overgrowth"] = {
		name = "overgrowth",
		animation = "overgrowth",
		element = "life",
		damage = 8,
	},
	["splash"] = {
		name = "splash",
		animation = "splash",
		element = "water",
		damage = 8,
	},
	["rock toss"] = {
		name = "rock toss",
		animation = "rock toss",
		element = "earth",
		damage = 8,
	},
	["tackle"] = {
		name = "tackle",
		animation = "tackle",
		element = "normal",
		damage = 8,
	},
	["hard tackle"] = {
		name = "hard tackle",
		animation = "tackle",
		element = "normal",
		damage = 6,
		skipswapattack = true,
	},
}

protomonbattle_protomon = {
	[1] = {
		name = "charenok",
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
			["tackle"] = true,
		},
		bonuses = {
			[1] = {
				cost = 1,
				addons = {attacks = {["hard tackle"] = true}},
			},
			[2] = {
				cost = 1,
				addons = {attacks = {["zap"] = true}},
			},
			[3] = {
				cost = 2,
				addons = {attacks = {["overgrowth"] = true}},
			},
			[4] = {
				cost = 2,
				addons = {attacks = {["splash"] = true}},
			},
			[5] = {
				cost = 1,
				addons = {attacks = {["rock toss"] = true}},
			},
			[6] = {
				cost = 2,
				addons = {switchattack = "inferno"},
			},
		},
	},
	[2] = {
		name = "vindchu",
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
			["tackle"] = true,
		},
		bonuses = {
			[1] = {
				cost = 1,
				addons = {attacks = {["hard tackle"] = true}},
			},
			[2] = {
				cost = 1,
				addons = {attacks = {["overgrowth"] = true}},
			},
			[3] = {
				cost = 2,
				addons = {attacks = {["splash"] = true}},
			},
			[4] = {
				cost = 2,
				addons = {attacks = {["rock toss"] = true}},
			},
			[5] = {
				cost = 1,
				addons = {attacks = {["hot foot"] = true}},
			},
			[6] = {
				cost = 2,
				addons = {switchattack = "lightning bolt"},
			},
		},
	},
	[3] = {
		name = "stemasaur",
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
			["tackle"] = true,
		},
		bonuses = {
			[1] = {
				cost = 1,
				addons = {attacks = {["hard tackle"] = true}},
			},
			[2] = {
				cost = 1,
				addons = {attacks = {["splash"] = true}},
			},
			[3] = {
				cost = 2,
				addons = {attacks = {["rock toss"] = true}},
			},
			[4] = {
				cost = 2,
				addons = {attacks = {["hot foot"] = true}},
			},
			[5] = {
				cost = 1,
				addons = {attacks = {["zap"] = true}},
			},
			[6] = {
				cost = 2,
				addons = {switchattack = "vine whip"},
			},
		},
	},
	[4] = {
		name = "squig",
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
			["tackle"] = true,
		},
		bonuses = {
			[1] = {
				cost = 1,
				addons = {attacks = {["hard tackle"] = true}},
			},
			[2] = {
				cost = 1,
				addons = {attacks = {["rock toss"] = true}},
			},
			[3] = {
				cost = 2,
				addons = {attacks = {["hot foot"] = true}},
			},
			[4] = {
				cost = 2,
				addons = {attacks = {["zap"] = true}},
			},
			[5] = {
				cost = 1,
				addons = {attacks = {["overgrowth"] = true}},
			},
			[6] = {
				cost = 2,
				addons = {switchattack = "torrent"},
			},
		},
	},
	[5] = {
		name = "boulderdude",
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
			["tackle"] = true,
		},
		bonuses = {
			[1] = {
				cost = 1,
				addons = {attacks = {["hard tackle"] = true}},
			},
			[2] = {
				cost = 1,
				addons = {attacks = {["hot foot"] = true}},
			},
			[3] = {
				cost = 2,
				addons = {attacks = {["zap"] = true}},
			},
			[4] = {
				cost = 2,
				addons = {attacks = {["overgrowth"] = true}},
			},
			[5] = {
				cost = 1,
				addons = {attacks = {["splash"] = true}},
			},
			[6] = {
				cost = 2,
				addons = {switchattack = "earth smash"},
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
