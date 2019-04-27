def download_candidates
    pn = Pathname.new("aec-senate-candidateinformation-20499.csv")

    unless pn.exist?()
        require 'open-uri'
        require 'zip/zip'
        content = open('https://results.aec.gov.au/20499/Website/External/aec-senate-candidateinformation-20499.zip')

        Zip::ZipFile.open(content) { |zip_file|
            zip_file.each { |f|
                zip_file.extract(f, f.name) unless File.exist?(f.name)
            }
        }
        puts "downloaded candidate list"
    end
end

def process_candidates(state)
    candidates = Array.new
    cnt = 0
    
    CSV.foreach("aec-senate-candidateinformation-20499.csv") do |row|
        unless row[2] == state && row[1] == 'S'
            next
        end
        candidates << Candidate.new(cnt,row[4],row[5],row[6],row[8])
        cnt += 1
    end
    puts "There are #{candidates.count} candidates."
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
    def initialize(cnt, ticket, ticket_position, surname, party)
        @ticket = ticket
        @ticket_position = ticket_position.to_i
        @surname = surname
        @party = party
        @cur_votes = [0]
        @cur_papers = 0
        @excluded = false
        @elected = false
        @elected_order = 0
        @elected_round = 0
        @order = cnt
        @distributed = false
        @transfers = Hash.new(0)
        @recent_round_count = 0
    end

    attr_reader :ticket, :surname, :ticket_position, :order
    attr_accessor :cur_votes, :excluded, :elected, :elected_order, :cur_papers, :distributed, :distributed, :elected_round, :transfers, :recent_round_count
end