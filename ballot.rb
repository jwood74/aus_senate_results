class Ballot
	def initialize(candidates_to_elect, state)
		@candidates = process_candidates(state)
		@tickets = process_tickets(@candidates)
		@votes = process_ballot_papers(state)
		@current_total = @votes.count
		@candidates_to_elect = candidates_to_elect
		@quota = calculate_quota
		@candidates_elected = 0
		@cur_candidate_count = @candidates.count
	end

	attr_reader :quota, :candidates_elected

	def calculate_quota
		return (@current_total / (@candidates_to_elect + 1)) + 1
	end
end


class BallotPaper
	def initialize(elec,booth_id,batch,paper,prefs)
		@elec = elec
		@booth_id = booth_id.to_i
		@batch = batch.to_i
		@paper = paper.to_i
		@atl = fix_pref(prefs.split(",")[0..37])
		@btl = fix_pref(prefs.split(",")[38..159])
		@btl_formal = check_btl_formal
		@atl_formal = check_atl_formal
		@cur_candidate = nil
		@is_exhaust = false
		@value = 1.0
	end

	attr_reader :btl_formal, :btl, :paper, :batch, :atl_formal, :atl

	def check_btl_formal
		if @btl.nil?
			return false
		# elsif  ((@btl.count("1") + @btl.count("*") + @btl.count("/")) == 1) && @btl.count("2") == 1 && @btl.count("3") == 1 && @btl.count("4") == 1 && @btl.count("5") == 1 && @btl.count("6") == 1 # && @btl.count("7") == 1 && @btl.count("8") == 1 && @btl.count("9") == 1 && @btl.count("10") == 1 && @btl.count("11") == 1 && @btl.count("12") == 1
		elsif  @btl.count(1) == 1 && @btl.count(2) == 1 && @btl.count(3) == 1 && @btl.count(4) == 1 && @btl.count(5) == 1 && @btl.count(6) == 1 # && @btl.count("7") == 1 && @btl.count("8") == 1 && @btl.count("9") == 1 && @btl.count("10") == 1 && @btl.count("11") == 1 && @btl.count("12") == 1	
			return true
		else
			return false
		end
	end

	def check_atl_formal
		if @btl_formal
			return false
		# elsif (@atl.count("1") + @atl.count("*") + @atl.count("/")) == 1
		elsif @atl.count(1) == 1
			return true
		else
			return false
		end
	end

	def fix_pref(pref)
		result = Array.new
		if pref.nil?
			return nil
		else
			pref.each do |b|
				if b.empty?
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
end