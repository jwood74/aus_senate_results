class BallotPaper
	def initialize(elec,booth_id,batch,paper,prefs,tickets)
		@elec = elec
		@booth_id = booth_id.to_i
		@batch = batch.to_i
		@paper = paper.to_i
		@btl = fix_pref(prefs[tickets..-1])
		@atl = fix_pref(prefs[0..(tickets - 1)])
		@btl_formal = check_btl_formal
		@atl_formal = check_atl_formal
		@cur_candidate = nil
		@is_exhaust = false
		@value = 1.0
		@round_last_updated = 1
	end

	attr_reader :btl_formal, :paper, :batch, :atl_formal, :atl
	attr_accessor :cur_candidate, :is_exhaust, :value, :btl, :round_last_updated

	def fix_pref(pref)
		result = Array.new
		if pref.nil?
			return nil
		else
			pref.each do |b|
				if b.nil? || b.empty?
					result << nil
				elsif b == '*' || b == '/'
					result << 1
				else
					result << b.to_i
				end
			end
			return result
		end

	end

	def check_btl_formal
		if btl.nil?
			return false
		elsif  btl.count(1) == 1 && self.btl.count(2) == 1 && self.btl.count(3) == 1 && self.btl.count(4) == 1 && self.btl.count(5) == 1 && self.btl.count(6) == 1
			return true
		else
			return false
		end
	end

	def check_atl_formal
		if self.btl_formal
			return false
		elsif self.atl.count(1) == 1
			return true
		else
			return false
		end
	end
end