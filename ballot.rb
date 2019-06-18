class Ballot
	def initialize(candidates_to_elect, election_code,state, candidates_to_exclude)
		@candidates = process_candidates(election_code,state, candidates_to_exclude)
		@tickets = process_tickets(election_code, state)
		@votes = process_ballot_papers(election_code,state,tickets.count)
		@current_total = @votes.count
		@candidates_to_elect = candidates_to_elect
		@quota = calculate_quota
		@candidates_elected = 0
		@cur_candidate_count = @candidates.count - candidates_to_exclude.count
		@current_exhaust = 0
		@fraction_lost = 0
		@state = state
		@pending_distribution = 0
		@candidates_to_exclude = candidates_to_exclude
	end

	attr_reader :quota, :tickets, :candidates_to_elect, :state, :candidates_to_exclude
	attr_accessor :votes, :candidates, :candidates_elected, :current_exhaust, :current_total, :cur_candidate_count, :fraction_lost, :pending_distribution

	def calculate_quota
		return (@current_total / (@candidates_to_elect + 1)) + 1
	end

	def process_btl_first_preference
		puts "Processing the BTL votes"
		bar = ProgressBar.new(self.current_total)
	
		self.votes.each do |v|
			bar.increment!

			cur_pref = 0

			self.candidates.count.times do |t|
				next_pref = (cur_pref + 1 + t)
				if not v.btl.count(next_pref) == 1
					v.is_exhaust = true
					v.cur_candidate = nil
					break
				end
				if self.candidates[v.btl.index(next_pref)].excluded || self.candidates[v.btl.index(next_pref)].elected
					next
				else
					v.cur_candidate = v.btl.index(next_pref)
					self.candidates[v.cur_candidate].cur_papers += 1
					self.candidates[v.cur_candidate].cur_votes[0] += 1
					self.candidates[v.cur_candidate].transfers[1.0] += 1
					break
				end
			end
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
				break if v.atl.count(atl_preference) > 1
				tik = self.tickets[box]
				ticket_complete = false
				ticket_pos = 1
				until ticket_complete
					self.candidates.each do |c|
						updated = false
						next if c.ticket != tik
						next if c.ticket_position != ticket_pos
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

	def print_current_votes(round)

		puts "Subtotal" unless round == 1
		puts
 
		display_candidates = self.candidates.sort_by { |x| x.cur_votes.last + (x.elected_order * 1000)}.reverse
		tot = 0
	 
		display_candidates.each do |c|
			if c.excluded && c.distributed
				next
			end
			tot += c.cur_votes.last
			puts "  Candidate #{c.surname} is on #{c.cur_votes.last} votes (#{c.cur_papers} ballots). #{' ## elected ' + c.elected_order.to_s + ' ##' unless c.elected == false}"
		end
		puts
		puts "#{tot} votes remaining in count. #{self.current_exhaust} votes have exhausted (#{self.fraction_lost.round} lost to fractions). #{self.cur_candidate_count} candidates remaining. Current Quota - #{self.quota}"
		puts
	end

	def print_distributed_votes(round, candidate, x)

		display_candidates = self.candidates.sort_by { |x| x.recent_round_count + (x.elected_order * 1000)}.reverse
		exh = 0
		exh_v = 0.0
		frac = 0
		tot = 0

		puts
		# candidate.cur_votes << candidate.cur_votes.last + (candidate.recent_round_count * x).ceil

		if candidate.excluded
			candidate.cur_votes << candidate.cur_votes.last - candidate.transfers[x]
		else
			candidate.cur_votes << candidate.cur_votes.last + (candidate.recent_round_count * x).ceil
		end

		display_candidates.each do |c|
			if c.excluded || (c.elected && c.elected_round < round)
				next
			end
			tmp = c.recent_round_count * x
			c.cur_votes << c.cur_votes.last + tmp.floor
			c.transfers[x] += tmp.floor if c.recent_round_count > 0
			puts "	Candidate #{c.surname} received #{c.recent_round_count} votes (worth #{(c.recent_round_count * x).floor})"
			# c.transfers |= [x] if c.recent_round_count > 0
		end
	
		self.votes.each do |v|
			if v.round_last_updated == round
				if v.is_exhaust
					exh += 1
					exh_v += x
				end
			end
		end

		self.current_exhaust += exh_v.floor

		# export(self, round, x, candidate.order)

		self.candidates.each do |c|
			c.recent_round_count = 0
			tot += c.cur_votes.last
		end

		frac = self.current_total - tot - self.fraction_lost - self.current_exhaust

		self.fraction_lost += frac.round
	
		puts "	Exhuasted #{exh} votes (worth #{exh_v.floor})"
		puts "	#{frac.round} lost to fractions"
		puts
	end
end


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