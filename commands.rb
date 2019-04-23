def setup(load_in, candidates_to_elect, state)
	if load_in
		puts "Loading the file"
		ballot = Marshal.load(File.read('ballot.b'))
	else
		ballot = Ballot.new(candidates_to_elect,state)
	
		ballot.process_btl_first_preference
		ballot.process_atl_preferences
	
		puts "Writing the file to disc"
		File.open("ballot.b","wb") {|f| f.write(Marshal.dump(ballot))}
	end
	return ballot
end

def download_results(state)
    pn = Pathname.new("aec-senate-formalpreferences-20499-#{state}.csv")

    unless pn.exist?()
        require 'open-uri'
        require 'zip/zip'
        content = open("https://results.aec.gov.au/20499/Website/External/aec-senate-formalpreferences-20499-#{state}.zip")

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

	filename = "aec-senate-formalpreferences-20499-#{state}.csv"
	line_count = `wc -l "#{filename}"`.strip.split(' ')[0].to_i

	ballot_papers = Array.new
	bar = ProgressBar.new(line_count - 2)

	CSV.foreach(filename).with_index(1) do |row, ln|
		if ln == 1 || ln == 2
			next
		end
		# next unless row[2] == "1" && row[3] == "26" && row[4] == "47"

		b = BallotPaper.new(row[0],row[2],row[3],row[4],row[5],tickets)
		ballot_papers << b
		bar.increment!
		 
		if $debug && ln == 2000
			break
		end

	 	# if ln % 200000 == 0
	 	# 	File.open("ballots_#{ln}.b","wb") {|f| f.write(Marshal.dump(ballot_papers))}
	 	# 	ballot_papers = Array.new
		# end
		
	end

	# File.open("ballots_last.b","wb") {|f| f.write(Marshal.dump(ballot_papers))}
	puts "There are #{ballot_papers.count} ballot papers."
	return ballot_papers
end

def load_ballots
	bar = ProgressBar.new(2723166)
	ballots = Marshal.load(File.read('ballots_200000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_400000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_600000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_800000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_1000000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_1200000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_1400000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_1600000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_1800000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_2000000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_2200000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_2400000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_2600000.b'))
	bar.increment!(200000)
	ballots += Marshal.load(File.read('ballots_last.b'))
	bar.increment!(123166)
	puts ballots.count.to_s + " loaded"
	return ballots
end

def check_for_elected(ballot,round)
    display_candidates = ballot.candidates.sort_by { |x| x.cur_votes }.reverse
 
    display_candidates.each do |c|
        if c.excluded || c.elected
            next
        end
        if c.cur_votes >= ballot.quota
            c.elected = true
            ballot.candidates_elected += 1
			c.elected_order = ballot.candidates_elected
			c.elected_round = round
			puts "Candidate #{c.surname} has been elected."
			ballot.cur_candidate_count -= 1
        end
    end
end

def find_lowest(ballot)
    lowest = ""
    lowest_votes = Float::INFINITY
 
    ballot.candidates.each do |c|
        if c.excluded || c.elected
            next
        end
        if c.cur_votes < lowest_votes
            lowest_votes = c.cur_votes
            lowest = c
        end
    end
    lowest.excluded = true
    ballot.cur_candidate_count -= 1
    # puts "Candidate #{lowest.name} has the least votes. Their votes will now be distributed."
    return lowest
end

def who_to_distribute(ballot)
	lowest = ""
	lowest_votes = Float::INFINITY
	highest = ""
	highest_votes = Float::INFINITY

	ballot.candidates.each do |c|
		if c.distributed
			next
		end
		if c.cur_votes < lowest_votes and c.elected == false
			lowest_votes = c.cur_votes
			lowest = c
		elsif c.elected == true and c.elected_order < highest_votes and c.cur_votes >= ballot.quota
			highest_votes = c.elected_order
			highest = c
		end

		# elsif c.cur_votes > highest_votes and c.elected and c.distributed == false
		# 	highest_votes = c.cur_votes
		# 	highest = c
		# end
	end

	if highest == ""
		puts "Candidate #{lowest.surname} has the least votes. Their votes will now be distributed."
		puts "Votes will be distributed in order of transfer value: #{lowest.transfers.to_s}"
		lowest.excluded = true
		ballot.cur_candidate_count -= 1
		return lowest
	else
		return highest
	end
end

def distribute_votes(ballot,round,candidate)
	puts
	
 
    cnt = 0.0
	tmp = Array.new

	vote_values = candidate.transfers.sort.reverse

	vote_values.each do |x|
		bar = ProgressBar.new(ballot.votes.count)

		if candidate.elected
			x = (candidate.cur_votes - ballot.quota) / candidate.cur_papers
			candidate.cur_votes = ballot.quota
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
					if candidate.elected == false
						ballot.current_exhaust += v.value
					end
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
		round += 1
		puts "** COUNT #{round} **"

		if candidate.elected
			break
		end
	end
	candidate.distributed = true
	return round
end