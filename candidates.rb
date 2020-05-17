def download_candidates(election_code,state)
    pn = Pathname.new("CSVs/aec-senate-formalpreferences-#{election_code}-#{state}.csv")

    unless pn.exist?()
        require 'open-uri'
        require 'zip/zip'
        content = open("https://results.aec.gov.au/#{election_code}/Website/External/aec-senate-formalpreferences-#{election_code}-#{state}.zip")

        Zip::ZipFile.open(content) { |zip_file|
            zip_file.each { |f|
                zip_file.extract(f, "CSVs/#{f.name}") unless File.exist?("CSVs/#{f.name}")
            }
        }
        puts "downloaded candidate list"
    end
end

def process_candidates(election_code, state, candidates_to_exclude)
    candidates = Array.new
    cnt = 0
    tik_cnt = 0
    tik = 'A'
    start = false
    
    CSV.foreach("CSVs/aec-senate-formalpreferences-#{election_code}-#{state}.csv") do |row|
        row.each_with_index do |c,i|
            unless i > 10
                next
            end
            
            unless c.split(':').first == 'A' || start
                next
            end
            start = true

            if c.split(':').first == tik
                tik_cnt += 1
            else
                tik_cnt = 1
                tik = c.split(':').first
            end
            candidates << Candidate.new(cnt,c.split(':').first,tik_cnt,c.split(':').last.split(' ').first,nil,(candidates_to_exclude.include? (cnt + 1)))
            cnt += 1
        end
        break
    end
    puts "There are #{candidates.count - candidates_to_exclude.count} candidates."
    return candidates
end

def process_tickets(election_code,state)
    tickets = Array.new

    CSV.foreach("CSVs/aec-senate-formalpreferences-#{election_code}-#{state}.csv") do |row|
        tik = ''
        row.each_with_index do |c,i|
            unless i > 5
                next
            end

            if c.split(':').first == 'A' && i > 12
                break
            end

            if c.split(':').first == tik
                next
            else
                # tickets << {c.split('_').first <= c.split('_').last}
                tickets << c.split(':').first 
                tik = c.split(':').first
            end
        end
        break
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
        @cur_papers = []
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