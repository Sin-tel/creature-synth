function clip(x)
	if(x <= -1) then
		return -2/3
	elseif(x >= 1) then
		return 2/3
	else
		return x-(x^3)/3
	end
end


function Filter(params)
	local params = params or {type = "bp", g = 0.5, r = 0.5, h = 0.5}
	local state_1_, state_2_ = 0,0
	local amp = 0
	local freq = 1

	
	public = {
		update = function (fr,res)
			local f = fr
			if f >= 0.49 then f = 0.49 end
			freq = f
			params.g = math.tan(math.pi*f)
			params.r = 1.0 / res
			params.h = 1.0 / (1.0 + params.r * params.g + params.g * params.g)
		end;
		
		process = function (input)
			local hp, bp, lp
		    hp = (input - params.r * state_1_ - params.g * state_1_ - state_2_) * params.h
		    bp = params.g * hp + state_1_
		    state_1_ = params.g * hp + bp
		    lp = params.g * bp + state_2_
		    state_2_ = params.g * bp + lp

		    --amp = amp - 0.1*(amp-math.abs(bp))
			return lp
		end;

		processBp = function (input)
			local hp, bp, lp
		    hp = (input - params.r * state_1_ - params.g * state_1_ - state_2_) * params.h
		    bp = params.g * hp + state_1_
		    state_1_ = params.g * hp + bp
		    lp = params.g * bp + state_2_
		    state_2_ = params.g * bp + lp

		    --amp = amp - 0.1*(amp-math.abs(bp))
			return bp
		end;

		getFreq = function ()
			return freq
		end;
	}
	return public
end