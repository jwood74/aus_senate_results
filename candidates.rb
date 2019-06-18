def download_candidates(election_code)
    pn = Pathname.new("aec-senate-candidateinformation-#{election_code}.csv")

    unless pn.exist?()
        require 'open-uri'
        require 'zip/zip'
        content = open("https://results.aec.gov.au/#{election_code}/Website/External/aec-senate-candidateinformation-#{election_code}.zip")

        Zip::ZipFile.open(content) { |zip_file|
            zip_file.each { |f|
                zip_file.extract(f, f.name) unless File.exist?(f.name)
            }
        }
        puts "downloaded candidate list"
    end
end

def process_candidates(state, candidates_to_exclude)
    candidates = Array.new
    cnt = 0
    
    CSV.foreach("aec-senate-candidateinformation-#{election_code}.csv") do |row|
        unless row[2] == state && row[1] == 'S'
            next
        end
        candidates << Candidate.new(cnt,row[4],row[5],row[6],row[8],(candidates_to_exclude.include? (cnt + 1)))
        cnt += 1
    end
    puts "There are #{candidates.count - candidates_to_exclude.count} candidates."
    return candidates
end

def process_tickets(candidates)
    tickets = Array.new

    candidates.each do |c|
        if tickets.include?(c.ticket) || c.ticket == 'UG'
            next
        else
            tickets << c.ticket
        end
    end
    puts "There are #{tickets.count} tickets."
    return tickets
end

class Candidate
    def initialize(cnt, ticket, ticket_position, surname, party, exclude)
        @ticket = ticket
        @ticket_position = ticket_position.to_i
        @surname = surname
        @party = party
        @cur_votes = [0]
        @cur_papers = 0
        @excluded = exclude
        @elected = false
        @elected_order = 0
        @elected_round = 0
        @order = cnt
        @distributed = exclude
        @transfers = Hash.new(0)
        @recent_round_count = 0
    end

    attr_reader :ticket, :surname, :ticket_position, :order, :party
    attr_accessor :cur_votes, :excluded, :elected, :elected_order, :cur_papers, :distributed, :distributed, :elected_round, :transfers, :recent_round_count
end