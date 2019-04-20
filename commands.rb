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
	puts "There are #{ballot_papers.count} ballot_papers."
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

def count_pref(ballots, line)
	results = Array.new
	def results.[](i)
		fetch(i) {0}
	end
	ballots.each do |b|
		if line == 'btl' and b.btl_formal
			results[b.btl.find_index(1)+1] += 1
		elsif line == 'atl' and b.atl_formal
			results[b.atl.find_index(1)+1] += 1
		end
	end
	return results
end
			
def random_thing(ballots,pos)
	cnt = 0
	ballots.each do |b|
		# begin
			if b.btl_formal
				# if b.btl[0] == "1" || b.btl[0] == "*" || b.btl[0] == "/"
				if b.btl[pos] == 1
					# p b.btl
					cnt += 1
				end
			end
		# rescue => error
		# 	puts error
		# 	p b
		# 	exit
		# end
	end
	puts "There are #{cnt} votes!"
end