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
    
    CSV.foreach("aec-senate-candidateinformation-20499.csv").with_index(1) do |row, ln|
        unless row[2] == 'QLD' && row[1] == 'S'
            next
        end
        candidates << Candidate.new(row[4],row[5],row[6],row[8])
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
    def initialize(ticket, ticket_position, surname, party)
        @ticket = ticket
        @ticket_position = ticket_position
        @surname = surname
        @party = party
        @first_pref = 0
        @cur_votes = @first_pref.to_f
        @excluded = false
        @elected = false
        @elected_order = 0
    end

    attr_reader :ticket
end