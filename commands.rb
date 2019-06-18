def setup(candidates_to_elect, state, candidates_to_exclude)
	ballot = Ballot.new(candidates_to_elect,state, candidates_to_exclude)

	
	ballot.process_atl_preferences
	ballot.process_btl_first_preference
	return ballot
end

def download_results(election_code,state)
    pn = Pathname.new("aec-senate-formalpreferences-#{election_code}-#{state}.csv")

    unless pn.exist?()
        require 'open-uri'
        require 'zip/zip'
        content = open("https://results.aec.gov.au/#{election_code}/Website/External/aec-senate-formalpreferences-#{election_code}-#{state}.zip")

        Zip::ZipFile.open(content) { |zip_file|
            zip_file.each { |f|
                zip_file.extract(f, f.name) unless File.exist?(f.name)
            }
		}
		puts "downloaded results"
	end
end

def process_ballot_papers(state,tickets)
	puts "Processing the ballot papers"

	filename = "aec-senate-formalpreferences-#{election_code}-#{state}.csv"
	line_count = `wc -l "#{filename}"`.strip.split(' ')[0].to_i

	ballot_papers = Array.new
	bar = ProgressBar.new(line_count - 2)

	CSV.foreach(filename).with_index(1) do |row, ln|
		if ln == 1 || ln == 2
			next
		end

		# break if ln == 2000

		b = BallotPaper.new(row[0],row[2],row[3],row[4],row[5],tickets)
		ballot_papers << b
		bar.increment!

	end

	puts "There are #{ballot_papers.count} ballot papers."
	return ballot_papers
end

def check_for_elected(ballot,round)
    display_candidates = ballot.candidates.sort_by { |x| x.cur_votes.last }.reverse
 
    display_candidates.each do |c|
        if c.excluded || c.elected
            next
        end
        if c.cur_votes.last >= ballot.quota
            c.elected = true
            ballot.candidates_elected += 1
			c.elected_order = ballot.candidates_elected
			c.elected_round = round
			puts "Candidate #{c.surname} has been elected."
			ballot.cur_candidate_count -= 1
			if c.cur_votes == ballot.quota
				c.distributed = true
			else
				ballot.pending_distribution += 1
			end
        end
    end
end

def elect_remaining_candidates(ballot,round)
	display_candidates = ballot.candidates.sort_by { |x| x.cur_votes.last }.reverse
 
	display_candidates.each do |c|
		if c.excluded || c.elected
			next
		end
		c.elected = true
		ballot.candidates_elected += 1
		c.elected_order = ballot.candidates_elected
		c.elected_round = round
		puts "Candidate #{c.surname} has been elected (In accordance with s273(18))."
		ballot.cur_candidate_count -= 1
	end
end

def elect_leading_candidate(ballot,round)
	display_candidates = ballot.candidates.sort_by { |x| x.cur_votes.last }.reverse
 
	display_candidates.each do |c|
		if c.excluded || c.elected
			next
		end
		if ballot.candidates_elected < ballot.candidates_to_elect
			c.elected = true
			ballot.candidates_elected += 1
			c.elected_order = ballot.candidates_elected
			c.elected_round = round
			puts "Candidate #{c.surname} has been elected (In accordance with s273(17))."
			ballot.cur_candidate_count -= 1
		else
			c.excluded = true
			c.elected_order = ballot.candidates.count - ballot.cur_candidate_count - ballot.candidates_elected
			c.elected_round = round
			ballot.cur_candidate_count -= 1
		end
	end
end

def display_final_results(ballot)
	display_candidates = ballot.candidates.sort_by { |x| x.elected_order }
	
	puts
	puts "Distribution over. Below are the elected candidates"
	puts
	display_candidates.each do |c|
		next unless c.elected
		puts "#{c.elected_order} - #{c.surname} (#{c.party}) - Round #{c.elected_round}"
	end

	puts
	puts "Excluded candidates"
	puts
	display_candidates.each do |c|
		next unless c.excluded
		next if ballot.candidates_to_exclude.include? (c.order + 1)
		puts "#{c.elected_order} - #{c.surname} (#{c.party}) - Round #{c.elected_round}"
	end
end

def who_to_distribute(ballot,round)
	lowest = []
	lowest_votes = Float::INFINITY
	highest = ""
	highest_votes = Float::INFINITY

	ballot.candidates.each do |c|
		if c.distributed
			next
		end
		if c.cur_votes.last < lowest_votes and c.elected == false
			lowest_votes = c.cur_votes.last
			lowest = [c]
		elsif
			c.cur_votes.last == lowest_votes and c.elected == false
			lowest << c
		elsif c.elected == true and c.elected_order < highest_votes and c.cur_votes.last > ballot.quota and c.distributed == false
			highest_votes = c.elected_order
			highest = c
		end
	end

	if highest == ""
		
		if lowest.count > 1
			if lowest.first.cur_votes.count != lowest.last.cur_votes.count
				puts "broke"
				exit
			end
			low = Array.new
			lowest.first.cur_votes.count.times do |n|
				low = Array.new
				low_votes = Float::INFINITY
				lowest.each do |l|
					if l.cur_votes[-(n+1)] < low_votes
						low_votes = l.cur_votes[-(n+1)]
						low = [l]
					elsif low_votes == l.cur_votes[-(n+1)]
						low << l
					end
				end
				if low.count == 1
					lowest = low
					break
				end
			end
			if low.count > 2
				puts "intervention required"
				low.each_with_index do |l,m|
					puts "press #{m+1} to eliminate #{l.surname}"
				end
				selection = gets.chomp.to_i
				lowest = [low[selection - 1]]
			end
		end

		puts "Candidate #{lowest.first.surname} has the least votes. Their votes will now be distributed."
		puts "Votes will be distributed in order of transfer value: #{lowest.first.transfers.to_s}"
		ballot.pending_distribution += 1
		lowest.first.excluded = true
		ballot.cur_candidate_count -= 1
		lowest.first.elected_round = round - 1
		lowest.first.elected_order = ballot.candidates.count - ballot.cur_candidate_count - ballot.candidates_elected - ballot.candidates_to_exclude.count
		return lowest.first
	else
		return highest
	end
end

def distribute_votes(ballot,round,candidate)
	puts

    cnt = 0.0
	tmp = Array.new

	vote_values = candidate.transfers.keys.sort.reverse

	vote_values.each do |x|
		bar = ProgressBar.new(ballot.votes.count)

		if candidate.elected
			x = (candidate.cur_votes.last - ballot.quota).to_f / candidate.cur_papers
		end

		puts "Distributing the votes of #{candidate.surname}."
		puts "Transfer Value = #{x.round(2)}"

		ballot.votes.each do |v|
			bar.increment!
			next unless v.cur_candidate == candidate.order
			next if v.is_exhaust

			if candidate.excluded
				next unless v.value == x
			end

			ballot.candidates[v.cur_candidate].cur_papers -= 1
			candidate.recent_round_count -= 1
			cur_pref = v.btl[candidate.order]

			ballot.candidates.count.times do |t|
				next_pref = (cur_pref + 1 + t)
				if not v.btl.count(next_pref) == 1
					v.is_exhaust = true
					v.cur_candidate = nil
					v.round_last_updated = round
					break
				end
				if ballot.candidates[v.btl.index(next_pref)].excluded || ballot.candidates[v.btl.index(next_pref)].elected
					next
				else
					v.cur_candidate = v.btl.index(next_pref)
					ballot.candidates[v.cur_candidate].cur_papers += 1
					ballot.candidates[v.cur_candidate].recent_round_count += 1
					v.round_last_updated = round
					if candidate.elected
						v.value = x
					end
					break
				end
			end

		end

		ballot.print_distributed_votes(round, candidate, x)
		check_for_elected(ballot,round)
		ballot.print_current_votes(round)
		export(ballot, round)	
		break if end_condition(ballot, round)
		round += 1
		puts "** COUNT #{round} **"

		if candidate.elected
			break
		end
	end
	candidate.distributed = true
	ballot.pending_distribution -= 1
	return round
end

def end_condition(ballot, round)
	if ballot.pending_distribution == 1
		if ballot.cur_candidate_count == (ballot.candidates_to_elect - ballot.candidates_elected)
		  elect_remaining_candidates(ballot, round)
		  return true
		elsif ballot.cur_candidate_count == 2
		  elect_leading_candidate(ballot, round)
		  return true
		end
	elsif ballot.candidates_elected == ballot.candidates_to_elect
			return true
	else
		return false
	end
end

def export(ballot,round,x = nil, candidate = nil)
	if round == 1
		CSV.open("export_#{ballot.state}.csv", "wb") do |csv|
			cands = ["round"]
			votes = [round]
			ballot.candidates.each do |c|
				cands << c.order
				votes << c.cur_votes.last
			end
			cands << "exhaust"
			cands << "faction"
			cands << "value"
			csv << cands
			csv << votes
		end
	elsif x
		CSV.open("export_#{ballot.state}.csv", 'ab') do |outfile|
			votes = [candidate]
			ballot.candidates.each do |c|
				votes << c.recent_round_count
			end
			votes << 0
			votes << 0
			votes << x
			outfile << votes
		end
	else
		CSV.open("export_#{ballot.state}.csv", 'ab') do |outfile|
			votes = [round]
			ballot.candidates.each do |c|
				votes << c.cur_votes.last
			end
			votes << ballot.current_exhaust
			votes << ballot.fraction_lost
			votes << ""
			outfile << votes
		end
	end
end