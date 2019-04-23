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
		@current_exhaust = 0.0
		@fraction_lost = 0.0
	end

	attr_reader :quota, :tickets, :candidates_to_elect
	attr_accessor :votes, :candidates, :candidates_elected, :current_exhaust, :current_total, :cur_candidate_count, :fraction_lost

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
			self.candidates[t].cur_papers += 1
			v.cur_candidate = t
			
		end
	end

	def process_atl_preferences
		puts "Processing the atl preferences"
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
				ticket_pos = 1
				until ticket_complete
					self.candidates.each do |c|
						updated = false
						next if c.ticket != tik
						next if c.ticket_position != ticket_pos
						if preference == 1
							c.cur_votes += 1
							c.cur_papers += 1
							v.cur_candidate = c.order
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

	def print_current_votes(round)

		puts "Subtotal" unless round == 1
		puts
 
		display_candidates = self.candidates.sort_by { |x| x.cur_votes + (x.elected_order * 1000)}.reverse
	 
		display_candidates.each do |c|
			if c.excluded && c.distributed
				next
			end
			puts "  Candidate #{c.surname} is on #{c.cur_votes.round} votes (#{c.cur_papers} ballots). #{' ## elected ' + c.elected_order.to_s + ' ##' unless c.elected == false}"
					# (or #{(c.cur_votes.to_f / ballot.current_total * 100).round(2)}%)
		end
		puts
		puts "#{self.current_total.round(0)} votes remaining in count. #{self.current_exhaust} votes have exhausted (#{self.fraction_lost.round} lost to fractions). #{self.cur_candidate_count} candidates remaining. Current Quota - #{self.quota}"
		puts
	end

	def print_distributed_votes(round, candidate, x)

		display_candidates = self.candidates.sort_by { |x| x.recent_round_count + (x.elected_order * 1000)}.reverse
		exh = 0
		exh_v = 0.0
		frac = 0.0
	
		puts
		#TODO check if below subtract working
		candidate.cur_votes -= (candidate.recent_round_count * x).floor
		frac += (candidate.recent_round_count * x) - (candidate.recent_round_count * x).floor
		display_candidates.each do |c|
			if c.excluded || (c.elected && c.elected_round < round)
				next
			end
			tmp = c.recent_round_count * x
			c.cur_votes += tmp.floor
			frac += (tmp - tmp.floor)
			puts "	Candidate #{c.surname} received #{c.recent_round_count} votes (worth #{(c.recent_round_count * x).floor})"
			c.transfers |= [x] if c.recent_round_count > 0
			c.recent_round_count = 0
		end
	
		self.votes.each do |v|
			if v.round_last_updated == round
				if v.is_exhaust
					exh += 1
					exh_v += v.value
				end
			end
		end

		self.fraction_lost += frac
	
		puts "	Exhuasted #{exh} votes (worth #{exh_v.round(3)})"
		puts "	#{frac.floor} lost to fractions"
		puts
	end
end


class BallotPaper
	def initialize(elec,booth_id,batch,paper,prefs,tickets)
		@elec = elec
		@booth_id = booth_id.to_i
		@batch = batch.to_i
		@paper = paper.to_i
		@btl = fix_pref(prefs.split(",")[tickets..-1])
		@atl = fix_pref(prefs.split(",")[0..(tickets - 1)])
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