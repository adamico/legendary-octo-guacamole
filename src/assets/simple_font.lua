return {
		meta = {
			name = "Simple Font",
			author = "BlueFalconHD"
		},

		-- To get the pod, hold down shift and select all of the text sprites for your 
		-- font. Then paste it here as a pod, add a comma at the end, and define your 
		-- character properties.

		pod = --[[pod_type="gfx",region_w=8]]unpod("b64:bHo0AA0EAADSFgAA8xx7e2JtcD1weHUAQyAFBQQAJwAHIBcgFxAXABcAByxmbGFncz0wLHBhbl94CADIeT0wLHpvb209OH0sPQBACAQHMAIAETdCABEnQgAPQQAaBH4AfzAHIAcAJwB9ABwBfAA-BwBHvgAkA30AP2dANzcAGcAECAQQBxAHAAcABxD4AAECAB8QugAc7wAXABcQJyAHADcwBzAX-AAfEgd5AQFHABAX-wAfIPsAGl8BBgQHAPYAHTIgB2DuAD8XEAfoARwxBAcEOwBjEBcABwAXPQEPsgAaMQIHBDYAHwA8ACBDBQUEFzoAAYAADy4BHT8FBQRqASYF4gIvIBfiAiEEeABCRwAHMAIAD2kCKQECAA-6ACMPfAAfjwUEAEdAJ0BH8wAaMAMHBN4BADMBAGUDD6gBHy8gFw0EJgSlAS8HANEDHiUFBF0CAwQAAgIAD4IAHgN_AAQIAA8uAh0EwAARED4AEjAEAA_FABwxRyAHAgAfR30AHAPnAhFnRgEfF7wAHgJDBhFHBgAACAAPfgAjAagCD2sDIwKBAAQCAA_BAB4SVwcHAaYDH0c8ACAiJxA8AC8HMPoAJi8QJ-oAIwi3AQ_5ARwzAwgEqwMCAgAvACd8ABwkRyD3AAG3Aj8QFxC9ACAAUgYiJxD2Ag-DAB4FxQgvBzC_ASCABwgEB0AnICd2AwDaBjIQF0ACAA_EAB4BPwkRB64FHhfGAA8JAhgDAgAPAwMmL0cAigIsAgIAAAwBLwAHggAlDwQBKj9AJ0ACASQVR4YDAQIAD40CIg_CASkGQQAHyAUfEJECHgKDAgGDAQMEAACWBh8XjgAhAYgAIyAHCAAOlAEPRgAaHzBYASQQR8sGAgIAD6EDHTMDCASaAw_jBCUiACe7AABIAQ6AAA9BABg-ACdA7QsiIAgEtwAEBAAFMgUPogYiEEA7AA9eByQD5w0PWQMjFDCPCA8BAiICgQABeQAPgwAmBUQADwsLIwNBAAimBQ_FAB0mAwPFDA9MCx0ANQAXRwYAD_8NGk8IBFcA7gAiIwcwdQM-gAcQ6gAeD4ULHj8BAwSdAxpPAgMEAIsOHT8BAQSUABoQAnwBHyBmAB1PBAEEN9EPHCEQB-gGAKwNH0f0BRwBnQ83IAcQBAAfIEAAHScXEEAAPxAXIC4CHSMXEKEEEBCwDgCiAg8CCCARArEOFAcCAB8QPQAdAYMAAwIADxcCGzAFBQT7Bz8QRxCeBB1PBgEEV2oAGk8DBEdAwwYeIRcA3AABnQE-BxAXPwAcA90BAEQAD7wRHhEC4wsFAgAfFzwAHAfPAS8AJ7UEHB93xQIcA7AEBAQAD0sETTIDAgTZAA8REiJPADdANx0FHA9rABxfEBAE8PAxAM1QbT04fX0="),

		-- This just maps a specific sprite in the pod above to character.
		-- Determines the sprite to show for a string. Any spaces are ignored sprites

		chars = {
			"abcdefgh",
			"ijklmnop",
			"qrstuvwx",
			"yzABCDEF",
			"GHIJKLMN",
			"OPQRSTUV",
			"WXYZ1234",
			"567890*#",
			"!?\" '.;-",
			"$/%&()+_",
			"={}[]|\\,",
			"^@:     ",
		},

		-- Y-offset of the sprite when displayed. Useful for characters that
		-- don't match the height of the rest or that have descenders.

		ascent = {
			-3,0,-3,0,-3,0,-3,-1,
			-2,-2,-1,-1,-3,-3,-3,-3,
			-3,-3,-3,-1,-3,-3,-3,-3,
			-3,-3,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,-3,-2,
			0,0,0,0,0,-7,-2,-4,
			-1,0,0,0,0,0,-2,-7,
			-3,0,0,0,0,0,0,-7,
			0,-3,-4,0,0,0,0,0,
		},

		-- x-offset of sprites
		-- somewhat finnicky as of right now
		-- a negative value results in the character to the right of the one specified 
		-- being further away.	

		offset = {
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,-1,0,0, -- make period stand out more by adding spacing
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,-1,0,0,0,0,0,
		},

		-- Define special characters
		-- space maps to " "
		-- Undefined is what is shown when no sprite is mapped to a character.
		-- Undefined is the only required property for fonts.

		special = {
			space = --[[pod_type="gfx"]]unpod("b64:bHo0AAwAAAALAAAAsHB4dQBDIAUJBPAd"),
			undefined = --[[pod_type="gfx"]]unpod("b64:bHo0ABwAAAAaAAAA8AtweHUAQyAFCAQHIAcAJwA3ACcAJwA3AIcAFw==")
		}
}