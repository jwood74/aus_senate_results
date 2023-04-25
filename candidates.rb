def download_candidates(election_code, state)
  pn = Pathname.new("CSVs/aec-senate-formalpreferences-#{election_code}-#{state}.csv")

  return if pn.exist?

  # content = URI.open("https://tallyroom.aec.gov.au/External/aec-senate-formalpreferences-#{election_code}-#{state}.zip")
  content = URI.open("https://results.aec.gov.au/#{election_code}/Website/External/aec-senate-formalpreferences-#{election_code}-#{state}.zip")
  
  Zip::File.open(content) do |zip_file|
    zip_file.each do |f|
      zip_file.extract(f, "CSVs/#{f.name}") unless File.exist?("CSVs/#{f.name}")
    end
  end
  puts 'downloaded candidate list'
  
end

def process_candidates(election_code, state, candidates_to_exclude)
  candidates = []
  cnt = 0
  tik_cnt = 0
  tik = 'A'
  start = false
    
  CSV.foreach("CSVs/aec-senate-formalpreferences-#{election_code}-#{state}.csv") do |row|
    row.each_with_index do |c, i|
      next unless i > 10
        
      next unless c.split(':').first == 'A' || start

      start = true

      if c.split(':').first == tik
        tik_cnt += 1
      else
        tik_cnt = 1
        tik = c.split(':').first
      end
      candidates << Candidate.new(cnt, c.split(':').first, tik_cnt, c.split(':').last.split(' ').first, nil, candidates_to_exclude.include?(cnt + 1))
      cnt += 1
    end
    break
  end
  puts "There are #{candidates.count - candidates_to_exclude.count} candidates."
  print_candidates(election_code, state, candidates)
  candidates
end

def print_candidates(election_code, state, candidates)
  CSV.open("candidates_#{election_code}_#{state}.csv", 'w') do |csv|
    candidates.each do |c|
      csv << [c.ticket, c.ticket_position, c.surname, c.party]
    end
  end
end

def process_tickets(election_code, state)
  tickets = []

  CSV.foreach("CSVs/aec-senate-formalpreferences-#{election_code}-#{state}.csv") do |row|
    tik = ''
    row.each_with_index do |c, i|
      next unless i > 5

      break if c.split(':').first == 'A' && i > 12

      next if c.split(':').first == tik
        
      
      # tickets << {c.split('_').first <= c.split('_').last}
      tickets << c.split(':').first 
      tik = c.split(':').first
      
    end
    break
  end
  puts "There are #{tickets.count} tickets."
  tickets
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
