protomonbattle_animations = {
    ["place protoball"] = {
		{
			action = "place",
			label = "protoballtop",
			placement = {
				X = 14.5,
				Y = 12.649841308594,
				Z = -0.0001220703125,
				P = -2.7320569643052e-005,
				R = 2.3905666239443e-005,
				Yaw = -0.0004191460320726,
				S = 0.24999916553497,
				N = "Dome (Exile)"
			},
			delay = 0.5
		},
		{
			action = "place",
			label = "protoballbottom",
			placement = {
				X = 14.5,
				Y = 12.649963378906,
				Z = -0.000244140625,
				P = 4.071109768744e-013,
				R = -179.99998474121,
				Yaw = -0.00037133469595574,
				S = 0.24999937415123,
				N = "Dome (Aurin)"
			},
			delay = 0.5
		},
		{
			action = "link",
			parent = "protoballtop",
			child = "protoballbottom",
			delay = 0.5
		},
		{
			action = "place",
			label = "protoballtop",
			placement = {
				X = 14.5,
				Y = 15.649841308594,
				Z = -0.0001220703125,
				P = -2.7320569643052e-005,
				R = 2.3905666239443e-005,
				Yaw = -0.0004191460320726,
				S = 0.24999916553497,
				N = "Dome (Exile)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "protoballlight",
			placement = {
				X = 11.4990234375,
				Y = 1.857421875,
				Z = -0.0361328125,
				P = 0.30011987686157,
				R = 0.20999696850777,
				Yaw = 90.000015258789,
				S = 6.9999971389771,
				N = "Spotlight (Chua)"
			},
			delay = 0.4
		},
    },
	["remove protoball"] = {
        {
            action = "crate",
            label = "protoballlight",
            delay = 0.4
        },
		{
			action = "place",
			label = "protoballtop",
			placement = {
				X = 14.5,
				Y = 12.649841308594,
				Z = -0.0001220703125,
				P = -2.7320569643052e-005,
				R = 2.3905666239443e-005,
				Yaw = -0.0004191460320726,
				S = 0.24999916553497,
				N = "Dome (Exile)"
			},
			delay = 0.4
		},
        {
            action = "crate",
            label = "protoballbottom",
            delay = 0.4
        },
        {
            action = "crate",
            label = "protoballtop",
            delay = 0.4
        },
	},
	["tackle"] = {
		{
			action = "startmove",
			label = "protomon1",
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon1",
			placement = {
				X = 0,
				Y = 0,
				Z = 4.1,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon1",
			placement = {
				X = 0,
				Y = 0,
				Z = 4.1,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon1",
			placement = {
				X = 0,
				Y = 0,
				Z = 4.1,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon1",
			placement = {
				X = 0,
				Y = 0,
				Z = 4.1,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon1",
			placement = {
				X = 0,
				Y = 0,
				Z = 4.1,
			},
			delay = 0.3,
		},
		{
			action = "cancelmove",
			label = "protomon1",
			delay = 0.3,
		},
	},
	["rock toss"] = {
		{
			action = "place",
			label = "rock",
			placement = {
				X = 9.2916259765625,
				Y = 15.290954589844,
				Z = -0.4052734375,
				P = 18.924970626831,
				R = 27.166269302368,
				Yaw = 30.947093963623,
				S = 0.99999803304672,
				N = "Swirly Rock"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "rock",
			placement = {
				X = 4.2906494140625,
				Y = 15.29052734375,
				Z = -0.4105224609375,
				P = 18.924974441528,
				R = 27.166255950928,
				Yaw = 30.947067260742,
				S = 0.99999767541885,
				N = "Swirly Rock"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "rock",
			placement = {
				X = -0.7093505859375,
				Y = 15.290405273438,
				Z = -0.410400390625,
				P = 18.924980163574,
				R = 27.166248321533,
				Yaw = 30.947063446045,
				S = 0.99999749660492,
				N = "Swirly Rock"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "rock",
			placement = {
				X = -5.7095947265625,
				Y = 15.290344238281,
				Z = -0.4102783203125,
				P = 18.924976348877,
				R = 27.166240692139,
				Yaw = 30.947063446045,
				S = 0.99999743700027,
				N = "Swirly Rock"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "rock",
			placement = {
				X = -10.709350585938,
				Y = 15.290283203125,
				Z = -0.410400390625,
				P = 18.924966812134,
				R = 27.166244506836,
				Yaw = 30.94709777832,
				S = 0.99999755620956,
				N = "Swirly Rock"
			},
			delay = 0.4
		},
		{
			action = "crate",
			label = "rock",
			delay = 0.4,
		},
	},
    ["earth smash"] = {
        {
            action = "place",
            label = "cloud",
            placement = {
                X = 9.701171875,
                Y = 3.5390625,
                Z = 0.6678466796875,
                P = -83.030067443848,
                R = 148.5902557373,
                Yaw = -0.36664932966232,
                S = 5.2799983024597,
                N = "Extractor (Ikthian)"
            },
            delay = 2
        },
        {
            action = "place",
            label = "cloud",
            placement = {
                X = -8.06640625,
                Y = 3.5380859375,
                Z = 0.6673583984375,
                P = -83.030067443848,
                R = 148.59020996094,
                Yaw = -0.36656624078751,
                S = 5.2799973487854,
                N = "Extractor (Ikthian)"
            },
            delay = 1
        },
        {
            action = "place",
            label = "rock",
            placement = {
                X = -11.597900390625,
                Y = 23.322448730469,
                Z = -0.5902099609375,
                P = 39.772430419922,
                R = 47.12739944458,
                Yaw = 77.619621276855,
                S = 1.4999982118607,
                N = "Sandstone Step (Tiered)"
            },
            delay = 2
        },
        {
            action = "place",
            label = "rock",
            placement = {
                X = -11.59765625,
                Y = 16.099670410156,
                Z = -0.5902099609375,
                P = 39.772430419922,
                R = 47.127388000488,
                Yaw = 77.619621276855,
                S = 1.4999977350235,
                N = "Sandstone Step (Tiered)"
            },
            delay = 1
        },
        {
            action = "crate", -- remove the rock, identified by label
            label = "rock",
            delay = 0.4
        },
        {
            action = "crate", -- remove the dust cloud
            label = "cloud",
            delay = 0.4
        },
    },
	["overgrowth"] = {
		{
			action = "place",
			label = "vines",
			placement = {
				X = -9.9998779296875,
				Y = 14.058471679688,
				Z = 0.3753662109375,
				P = -0.078841149806976,
				R = -0.13509276509285,
				Yaw = 83.497932434082,
				S = 0.99999868869781,
				N = "Galeras Grass Patch (Large)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "vines",
			placement = {
				X = -9.4332275390625,
				Y = 14.184692382813,
				Z = 0.646484375,
				P = -0.078841030597687,
				R = -0.13509261608124,
				Yaw = 69.272682189941,
				S = 1.1999999284744,
				N = "Galeras Grass Patch (Large)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "vines",
			placement = {
				X = -10.6435546875,
				Y = 14.32373046875,
				Z = 0.3126220703125,
				P = -0.078840851783752,
				R = -0.13509261608124,
				Yaw = 69.272735595703,
				S = 1.4499990940094,
				N = "Galeras Grass Patch (Large)"
			},
			delay = 0.4
		},
		{
			action = "crate",
			label = "vines",
			delay = 0.4
		},
	},
    ["vine whip"] = {
		{
			action = "place",
			label = "vine",
			placement = {
				X = 9.1884765625,
				Y = 14.895263671875,
				Z = 0.12841796875,
				P = 0.603002846241,
				R = 11.043747901917,
				Yaw = -3.084400177002,
				S = 1.1499997377396,
				N = "Leafy Stalk 2"
			},
			delay = 1
		},
		{
			action = "place",
			label = "vine",
			placement = {
				X = 9.1884765625,
				Y = 14.895263671875,
				Z = 0.12841796875,
				P = 2.4075915813446,
				R = 49.96745300293,
				Yaw = -2.0205659866333,
				S = 1.1499999761581,
				N = "Leafy Stalk 2"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "vine",
			placement = {
				X = 9.1884765625,
				Y = 14.895263671875,
				Z = 0.12841796875,
				P = 3.1405673027039,
				R = 88.033996582031,
				Yaw = -0.10701468586922,
				S = 1.1500005722046,
				N = "Leafy Stalk 2"
			},
			delay = 1.5
		},
        {
            action = "crate",
            label = "vine",
            delay = 0.4
        },
    },
	["zap"] = {
		{
			action = "place",
			label = "zap",
			placement = {
				X = -10.03271484375,
				Y = 14.895751953125,
				Z = 0.6351318359375,
				P = -2.0117287931498e-005,
				R = -4.1148709897243e-006,
				Yaw = -0.00010154222400161,
				S = 0.9999840259552,
				N = "10:04 Lightning Bolt"
			},
			delay = 1
		},
		{
			action = "crate",
			label = "zap",
			delay = 0.3
		}
	},
	["lightning bolt"] = {
		{
			action = "place",
			label = "bolt",
			placement = {
				X = -10.03271484375,
				Y = 14.895751953125,
				Z = 0.6351318359375,
				P = -2.0117287931498e-005,
				R = -4.1148709897243e-006,
				Yaw = -0.00010154222400161,
				S = 0.9999840259552,
				N = "10:04 Lightning Bolt"
			},
			delay = 0.8
		},
		{
			action = "place",
			label = "bolt",
			placement = {
				X = -11.272705078125,
				Y = 14.895751953125,
				Z = -1.6304931640625,
				P = -2.0116985979257e-005,
				R = -4.1147991396429e-006,
				Yaw = -0.00012886297190562,
				S = 0.99997711181641,
				N = "10:04 Lightning Bolt"
			},
			delay = 0.8
		},
		{
			action = "place",
			label = "bolt",
			placement = {
				X = -12.636474609375,
				Y = 14.8955078125,
				Z = 1.2587890625,
				P = -2.0116858649999e-005,
				R = -4.1147645788442e-006,
				Yaw = -0.0001493535382906,
				S = 0.9999703168869,
				N = "10:04 Lightning Bolt"
			},
			delay = 0.8
		},
		{
			action = "crate",
			label = "bolt",
			delay = 0.4
		}
	},
	["splash"] = {
		{
			action = "place",
			label = "pond",
			placement = {
				X = -11.01806640625,
				Y = 11.732849121094,
				Z = 0.72412109375,
				P = -0.10547234117985,
				R = -0.61942988634109,
				Yaw = -73.672393798828,
				S = 0.20000007748604,
				N = "Waterfall Cascade (Single)"
			},
			delay = 0.5
		},
		{
			action = "place",
			label = "pond",
			placement = {
				X = -12.099609375,
				Y = 10.995788574219,
				Z = 0.2093505859375,
				P = -1.7143362760544,
				R = -1.515734910965,
				Yaw = -116.22248077393,
				S = 0.24999998509884,
				N = "Waterfall Cascade (Single)"
			},
			delay = 0.5
		},
		{
			action = "place",
			label = "pond",
			placement = {
				X = -13.7685546875,
				Y = 8.5925512695313,
				Z = -0.670166015625,
				P = -1.0841447114944,
				R = -0.23684261739254,
				Yaw = -116.25374603271,
				S = 0.40000000596046,
				N = "Waterfall Cascade (Single)"
			},
			delay = 1
		},
		{
			action = "crate",
			label = "pond",
			delay = 0.4
		}
	},
	["torrent"] = {
		{
			action = "place",
			label = "pond",
			placement = {
				X = -10.75341796875,
				Y = 4.5701293945313,
				Z = 5.6395263671875,
				P = -0.81197422742844,
				R = -0.52515816688538,
				Yaw = 0.0069376640021801,
				S = 0.64999836683273,
				N = "Waterfall Cascade (Single)"
			},
			delay = 1
		},
		{
			action = "place",
			label = "spout1",
			placement = {
				X = -12.43994140625,
				Y = 20.016967773438,
				Z = -6.6787109375,
				P = 6.5443941821286e-006,
				R = -179.99998474121,
				Yaw = 50.85941696167,
				S = 0.65000003576279,
				N = "Waterfall Cascade (Twin)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "spout2",
			placement = {
				X = -15.763793945313,
				Y = 17.287292480469,
				Z = -0.4720458984375,
				P = -3.4151114505221e-006,
				R = -179.99998474121,
				Yaw = 100.03298187256,
				S = 0.34999999403954,
				N = "Waterfall Cascade (Multiple)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "spout3",
			placement = {
				X = -7.2550048828125,
				Y = 18.631958007813,
				Z = 3.242919921875,
				P = 0.061353646218777,
				R = 179.80323791504,
				Yaw = -150.44879150391,
				S = 0.59999978542328,
				N = "Waterfall Cascade (Diverted)"
			},
			delay = 1
		},
		{
			action = "crate",
			label = "spout1",
			delay = 0.4
		},
		{
			action = "crate",
			label = "spout2",
			delay = 0.4
		},
		{
			action = "crate",
			label = "spout3",
			delay = 0.6
		},
		{
			action = "crate",
			label = "pond",
			delay = 0.4
		},
	},
    ["hot foot"] = {
		{
			action = "place",
			label = "flame1",
			placement = {
				X = -9.8260498046875,
				Y = 9.7487182617188,
				Z = -0.9464111328125,
				P = 6.4951018430293e-006,
				R = -1.4560294403054e-005,
				Yaw = 93.917373657227,
				S = 5.999990940094,
				N = "Candle (Medium)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "flame2",
			placement = {
				X = -12.536865234375,
				Y = 9.7489624023438,
				Z = 1.8658447265625,
				P = 6.495095021819e-006,
				R = -1.456029167457e-005,
				Yaw = 93.917373657227,
				S = 5.9999804496765,
				N = "Candle (Medium)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "flame3",
			placement = {
				X = -10.761596679688,
				Y = 9.7490234375,
				Z = 0.874267578125,
				P = 6.4950954765663e-006,
				R = -1.4560296222044e-005,
				Yaw = 93.917373657227,
				S = 5.9999785423279,
				N = "Candle (Medium)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "flame4",
			placement = {
				X = -12.315673828125,
				Y = 9.7489013671875,
				Z = -0.8980712890625,
				P = 6.4950968408084e-006,
				R = -1.456029167457e-005,
				Yaw = 93.917373657227,
				S = 5.9999823570251,
				N = "Candle (Medium)"
			},
			delay = 1
		},
        {
            action = "crate", 
            label = "flame1",
            delay = 0.4
        },
        {
            action = "crate", 
            label = "flame2",
            delay = 0.4
        },
        {
            action = "crate", 
            label = "flame3",
            delay = 0.4
        },
        {
            action = "crate", 
            label = "flame4",
            delay = 0.4
        },
	},
    ["inferno"] = {
        {
			action = "place",
            label = "blaze",
            placement = {
                
                X = 10.67724609375,
                Y = 14.895812988281,
                Z = 0.269287109375,
                P = -1.6577525457251e-005,
                R = 3.3609779848121e-007,
                Yaw = -2.7525992393494,
                S = 1.009999871254,
                N = "Burning Track"
            },
            delay = 1
        },
        {        
            action = "place",
            label = "blaze",
            placement = {
                X = 10.67724609375,
                Y = 14.895812988281,
                Z = 0.269287109375,
                P = -1.6577525457251e-005,
                R = 3.3609779848121e-007,
                Yaw = -2.7525992393494,
                S = 1.009999871254,
                N = "Burning Track"
            },
            delay = 1
        },
        {
            action = "place",
            label = "inferno",
            placement = {
                X = -9.9442138671875,
                Y = 0.81658935546875,
                Z = 1.5850830078125,
                P = -1.0706598914112e-005,
                R = -8.5064693848835e-006,
                Yaw = -1.3383357524872,
                S = 2.2399969100952,
                N = "Wicked Firetotem"
            },
            delay = 1
        },
        {
            action = "place",
            label = "inferno",
            placement = {
                X = -8.294189453125,
                Y = -8.0825805664063,
                Z = 1.9818115234375,
                P = -1.0706595276133e-005,
                R = -8.5064702943782e-006,
                Yaw = -1.3383356332779,
                S = 3.4899981021881,
                N = "Wicked Firetotem"
            },
            delay = 1
        },
        {
            action = "crate", 
            label = "inferno",
            delay = 0.4
        },
        {
            action = "crate",
            label = "blaze",
            delay = 0.4
        }
    },
	["fusion beam"] = {
		{
			action = "place",
			label = "aura",
			placement = {
				X = -5.645849609375,
				Y = 16.312744140625,
				Z = -0.0009765625,
				P = -1.5630822192136e-009,
				R = 179.99998474121,
				Yaw = 90,
				S = 3.9999985694885,
				N = "Medical Cot (Hovering)"
			},
			delay = 0.7
		},
		{
			action = "place",
			label = "beam",
			placement = {
				X = 0.345703125,
				Y = -3.8861083984375,
				Z = 0.0048828125,
				P = -7.1716982347425e-005,
				R = -22.240535736084,
				Yaw = -0.00037474976852536,
				S = 3.9999983310699,
				N = "Energy Barrier (Ikthian)"
			},
			delay = 0.4
		},
		{
			action = "startmove",
			label = "protomon2",
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon2",
			placement = {
				X = 0,
				Y = 0,
				Z = 0.5,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon2",
			placement = {
				X = 0,
				Y = 0,
				Z = -0.5,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon2",
			placement = {
				X = 0,
				Y = 0,
				Z = 0.5,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon2",
			placement = {
				X = 0,
				Y = 0,
				Z = -0.5,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon2",
			placement = {
				X = 0,
				Y = 0,
				Z = 0.5,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon2",
			placement = {
				X = 0,
				Y = 0,
				Z = -0.5,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon2",
			placement = {
				X = 0,
				Y = 0,
				Z = 0.5,
			},
			delay = 0.1,
		},
		{
			action = "move",
			label = "protomon2",
			placement = {
				X = 0,
				Y = 0,
				Z = -0.5,
			},
			delay = 0.1,
		},
		{
			action = "cancelmove",
			label = "protomon2",
			delay = 0.4,
		},
        {
            action = "crate",
            label = "aura",
            delay = 0.4
        },
        {
            action = "crate",
            label = "beam",
            delay = 0.4
        },
	},
	["explosive egg"] = {
		{
			action = "place",
			label = "egg",
			placement = {
				X = -8.835205078125,
				Y = 14.739990234375,
				Z = 0.033203125,
				P = -0.15645287930965,
				R = 0.0015211837599054,
				Yaw = -0.0002279016043758,
				S = 0.34999939799309,
				N = "Spider Egg (White)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "egg",
			placement = {
				X = -8.835205078125,
				Y = 14.729858398438,
				Z = 0.033203125,
				P = -0.15645281970501,
				R = 0.0015211970312521,
				Yaw = -0.0002859584055841,
				S = 0.49999976158142,
				N = "Spider Egg (White)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "egg",
			placement = {
				X = -8.835205078125,
				Y = 14.729858398438,
				Z = 0.032958984375,
				P = -0.15645280480385,
				R = 0.0015212435973808,
				Yaw = -0.00035426052636467,
				S = 0.64999979734421,
				N = "Spider Egg (White)"
			},
			delay = 0.8
		},
		{
			action = "crate",
			label = "egg",
			delay = 0.4,
		},
		{
			action = "place",
			label = "explode",
			placement = {
				X = -9.52880859375,
				Y = 14.99755859375,
				Z = 0.03271484375,
				P = 3.0774128134681e-008,
				R = -179.99998474121,
				Yaw = 179.99995422363,
				S = 1.8999991416931,
				N = "10:04 Lightning Bolt"
			},
			delay = 0.8
		},
		{
			action = "crate",
			label = "explode",
			delay = 0.4,
		},
	},
	["sand kick"] = {
		{
			action = "place",
			label = "sand",
			placement = {
				X = -7.359619140625,
				Y = 5.0537109375,
				Z = -0.01220703125,
				P = -90,
				R = 0,
				Yaw = 90.000007629395,
				S = 4.4999961853027,
				N = "Extractor (Ikthian)"
			},
			delay = 4
		},
		{
			action = "crate",
			label = "sand",
			delay = 0.4,
		},
	},
	["mist spray"] = {
		{
			action = "place",
			label = "mist",
			placement = {
				X = 0.03466796875,
				Y = 12.6298828125,
				Z = -0.00146484375,
				P = 0.0012328489683568,
				R = 72.6728515625,
				Yaw = -0.0022257305681705,
				S = 3.4999907016754,
				N = "Flare (Blue)"
			},
			delay = 4.5
		},
		{
			action = "crate",
			label = "mist",
			delay = 0.4,
		},
	},
	["flash fire"] = {
		{
			action = "place",
			label = "lightning",
			placement = {
				X = -8.2708740234375,
				Y = 14.89013671875,
				Z = 0,
				P = -0.14551988244057,
				R = -21.576328277588,
				Yaw = 0.057449817657471,
				S = 0.49999997019768,
				N = "10:04 Lightning Bolt"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "fire",
			placement = {
				X = -12.369873046875,
				Y = -1.8294677734375,
				Z = 1.825927734375,
				P = -1.6588711559962e-007,
				R = 6.6701737466701e-009,
				Yaw = -90.000022888184,
				S = 2.4999871253967,
				N = "Wicked Firetotem"
			},
			delay = 0.4
		},
		{
			action = "crate",
			label = "lightning",
			delay = 4,
		},
		{
			action = "crate",
			label = "fire",
			delay = 0.4,
		},
	},
	["rock slide"] = {
		{
			action = "place",
			label = "rock",
			placement = {
				X = 9.2916259765625,
				Y = 15.290954589844,
				Z = -0.4052734375,
				P = 18.924970626831,
				R = 27.166269302368,
				Yaw = 30.947093963623,
				S = 0.99999803304672,
				N = "Swirly Rock"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "rock",
			placement = {
				X = 4.2906494140625,
				Y = 15.29052734375,
				Z = -0.4105224609375,
				P = 18.924974441528,
				R = 27.166255950928,
				Yaw = 30.947067260742,
				S = 0.99999767541885,
				N = "Swirly Rock"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "rock",
			placement = {
				X = -0.7093505859375,
				Y = 15.290405273438,
				Z = -0.410400390625,
				P = 18.924980163574,
				R = 27.166248321533,
				Yaw = 30.947063446045,
				S = 0.99999749660492,
				N = "Swirly Rock"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "rock",
			placement = {
				X = -5.7095947265625,
				Y = 15.290344238281,
				Z = -0.4102783203125,
				P = 18.924976348877,
				R = 27.166240692139,
				Yaw = 30.947063446045,
				S = 0.99999743700027,
				N = "Swirly Rock"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "rock",
			placement = {
				X = -10.709350585938,
				Y = 15.290283203125,
				Z = -0.410400390625,
				P = 18.924966812134,
				R = 27.166244506836,
				Yaw = 30.94709777832,
				S = 0.99999755620956,
				N = "Swirly Rock"
			},
			delay = 0.4
		},
		{
			action = "crate",
			label = "rock",
			delay = 0.4
		},
	},
	["bio shock"] = {
		{
			action = "place",
			label = "shock",
			placement = {
				X = -14.204345703125,
				Y = 15.102966308594,
				Z = 0.101806640625,
				P = 4.7515377998352,
				R = -64.350875854492,
				Yaw = 22.222034454346,
				S = 0.74999791383743,
				N = "10:04 Lightning Bolt"
			},
			delay = 1
		},
		{
			action = "crate",
			label = "shock",
			delay = 0.3
		}
	},
	["hot steam"] = {
		{
			action = "place",
			label = "steam",
			placement = {
				X = -9.8662109375,
				Y = 14.889953613281,
				Z = 0.0001220703125,
				P = -0.15636786818504,
				R = -0.0041225622408092,
				Yaw = 2.0672073364258,
				S = 1.4999982118607,
				N = "Smoke Pillar (White)"
			},
			delay = 4
		},
		{
			action = "crate",
			label = "steam",
			delay = 0.4,
		},
	},
	["kelp growth"] = {
		{
			action = "place",
			label = "pond",
			placement = {
				X = -10.75341796875,
				Y = 4.5701293945313,
				Z = 5.6395263671875,
				P = -0.81197422742844,
				R = -0.52515816688538,
				Yaw = 0.0069376640021801,
				S = 0.64999836683273,
				N = "Waterfall Cascade (Single)"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "kelp1",
			placement = {
				X = -10.208251953125,
				Y = 13.045288085938,
				Z = -0.5972900390625,
				P = -0.086521774530411,
				R = -0.1303083896637,
				Yaw = 68.09171295166,
				S = 1.9999985694885,
				N = "Barnacleweed"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "kelp2",
			placement = {
				X = -12.365600585938,
				Y = 13.045166015625,
				Z = 0.89404296875,
				P = -0.086521603167057,
				R = -0.13030840456486,
				Yaw = -91.41535949707,
				S = 1.9999978542328,
				N = "Barnacleweed"
			},
			delay = 3
		},
		{
			action = "crate",
			label = "kelp2",
			delay = 0.4,
		},
		{
			action = "crate",
			label = "kelp1",
			delay = 0.4,
		},
		{
			action = "crate",
			label = "pond",
			delay = 0.4,
		},
	},
	["static shock"] = {
		{
			action = "place",
			label = "shock",
			placement = {
				X = 7.375244140625,
				Y = 14.891662597656,
				Z = -0.9532470703125,
				P = -0.15645675361156,
				R = -179.99847412109,
				Yaw = -5.4843887483003e-005,
				S = 0.49999991059303,
				N = "10:04 Lightning Bolt"
			},
			delay = 0.5
		},
		{
			action = "place",
			label = "shock",
			placement = {
				X = 4.47314453125,
				Y = 14.900451660156,
				Z = 2.26025390625,
				P = -0.15645675361156,
				R = -179.99847412109,
				Yaw = -5.4843887483003e-005,
				S = 0.49999386072159,
				N = "10:04 Lightning Bolt"
			},
			delay = 0.5
		},
		{
			action = "place",
			label = "shock",
			placement = {
				X = -2.14404296875,
				Y = 14.900451660156,
				Z = -1.7802734375,
				P = -0.15645675361156,
				R = -179.99847412109,
				Yaw = -5.4843887483003e-005,
				S = 0.4999934732914,
				N = "10:04 Lightning Bolt"
			},
			delay = 0.5
		},
		{
			action = "place",
			label = "shock",
			placement = {
				X = -6.2286376953125,
				Y = 14.900451660156,
				Z = 3.024658203125,
				P = -0.15645675361156,
				R = -179.99847412109,
				Yaw = -5.4843887483003e-005,
				S = 0.49999326467514,
				N = "10:04 Lightning Bolt"
			},
			delay = 0.5
		},
		{
			action = "place",
			label = "shock",
			placement = {
				X = -11.275756835938,
				Y = 14.900573730469,
				Z = -0.071533203125,
				P = -0.15645675361156,
				R = -179.99847412109,
				Yaw = -5.4843887483003e-005,
				S = 1.4999996423721,
				N = "10:04 Lightning Bolt"
			},
			delay = 1
		},
		{
			action = "crate",
			label = "shock",
			delay = 0.4,
		},
	},
	["mud bath"] = {
		{
			action = "place",
			label = "pit",
			placement = {
				X = -7.6094970703125,
				Y = -10.879943847656,
				Z = -2.480224609375,
				P = 9.0228796005249,
				R = -5.429988861084,
				Yaw = 68.520034790039,
				S = 3.8999962806702,
				N = "Young Buzzbing Hive"
			},
			delay = 0.4
		},
		{
			action = "place",
			label = "mud",
			placement = {
				X = -10.902587890625,
				Y = 8.6532592773438,
				Z = 0.4718017578125,
				P = -3.0315582752228,
				R = 1.7633758034208e-005,
				Yaw = -0.00026583523140289,
				S = 2.6999979019165,
				N = "Bubbling Cauldron (Skeech)"
			},
			delay = 0.4
		},
		{
			action = "link",
			parent = "pit",
			child = "mud",
			delay = 0.4
		},
		{
			action = "place",
			label = "pit",
			placement = {
				X = -7.6097412109375,
				Y = -8.8796997070313,
				Z = -2.4814453125,
				P = 9.0228853225708,
				R = -5.4287796020508,
				Yaw = 68.523635864258,
				S = 3.8999960422516,
				N = "Young Buzzbing Hive"
			},
			delay = 3
		},
		{
			action = "place",
			label = "pit",
			placement = {
				X = -7.6094970703125,
				Y = -10.879943847656,
				Z = -2.480224609375,
				P = 9.0228796005249,
				R = -5.429988861084,
				Yaw = 68.520034790039,
				S = 3.8999962806702,
				N = "Young Buzzbing Hive"
			},
			delay = 0.4
		},
		{
			action = "crate",
			label = "pit",
			delay = 0.4,
		},
		{
			action = "crate",
			label = "mud",
			delay = 0.4,
		},
	},
}