class Ballot
	def initialize(candidates_to_elect, state)
		@candidates = process_candidates(state)
		@tickets = process_tickets(@candidates)
		@votes = process_ballot_papers(state,tickets.count)
		@current_total = @votes.count
		@candidates_to_elect = candidates_to_elect
		@quota = calculate_quota
		@candidates_elected = 0
		@cur_candidate_count = @candidates.count
	end

	attr_reader :quota, :candidates_elected, :current_total, :tickets
	attr_accessor :votes, :candidates

	def calculate_quota
		return (@current_total / (@candidates_to_elect + 1)) + 1
	end

	def process_btl_first_preference
		bar = ProgressBar.new(self.current_total)
		self.votes.each do |v|
			# bar.increment!
			next if !v.btl_formal
			t = v.btl.find_index(1)
			self.candidates[t].first_pref += 1
			self.candidates[t].cur_votes += 1
			v.cur_candidate = t
			
		end
	end

	def process_atl_preferences
		puts "processing the atl preferences"
		bar = ProgressBar.new(self.current_total)
		self.votes.each do |v|
			bar.increment!
			next if v.btl_formal
			checking = true
			v.btl = Array.new

			atl_preference = 1
			preference = 1
			updated = false

			while checking
				box = v.atl.find_index(atl_preference)
				break if box.nil?
				tik = self.tickets[box]
				ticket_complete = false
				cands = self.candidates.select {|c| c.ticket == tik}
				ticket_pos = 1
				until ticket_complete
					cands.each do |c|
						updated = false
						next if c.ticket_position != ticket_pos
						if preference == 1
							c.cur_votes += 1
							v.cur_candidate = box
						end
						v.btl[c.order] = preference
						ticket_pos += 1
						preference += 1
						updated = true
					end
					ticket_complete = true if updated == false
				end
				atl_preference += 1
			end
		end
	end

	def print_first_preference
		display_candidates = self.candidates.sort_by { |x| x.cur_votes }.reverse
	 
		display_candidates.each do |c|
			puts "  Candidate #{c.surname} received #{c.cur_votes.round} first preference votes"
		end
		puts "#{self.current_total} votes remaining in count"
		puts
	end
end


class BallotPaper
	def initialize(elec,booth_id,batch,paper,prefs,tickets)
		@elec = elec
		@booth_id = booth_id.to_i
		@batch = batch.to_i
		@paper = paper.to_i
		@btl = fix_pref(prefs.split(",")[38..159])
		@atl = fix_pref(prefs.split(",")[0..(tickets - 1)])
		@btl_formal = check_btl_formal
		@atl_formal = check_atl_formal
		@cur_candidate = nil
		@is_exhaust = false
		@value = 1.0
	end

	attr_reader :btl_formal, :paper, :batch, :atl_formal, :atl
	attr_accessor :cur_candidate, :is_exhaust, :value, :btl

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

	def check_btl_formal
		if btl.nil?
			return false
		# elsif  ((@btl.count("1") + @btl.count("*") + @btl.count("/")) == 1) && @btl.count("2") == 1 && @btl.count("3") == 1 && @btl.count("4") == 1 && @btl.count("5") == 1 && @btl.count("6") == 1 # && @btl.count("7") == 1 && @btl.count("8") == 1 && @btl.count("9") == 1 && @btl.count("10") == 1 && @btl.count("11") == 1 && @btl.count("12") == 1
		elsif  btl.count(1) == 1 && self.btl.count(2) == 1 && self.btl.count(3) == 1 && self.btl.count(4) == 1 && self.btl.count(5) == 1 && self.btl.count(6) == 1 # && @btl.count("7") == 1 && @btl.count("8") == 1 && @btl.count("9") == 1 && @btl.count("10") == 1 && @btl.count("11") == 1 && @btl.count("12") == 1	
			return true
		else
			return false
		end
	end

	def check_atl_formal
		if self.btl_formal
			return false
		# elsif (@atl.count("1") + @atl.count("*") + @atl.count("/")) == 1
		elsif self.atl.count(1) == 1
			return true
		else
			return false
		end
	end
end