class Ballot
  def initialize(candidates_to_elect, election_code, state, candidates_to_exclude)
    @candidates = process_candidates(election_code, state, candidates_to_exclude)
    @tickets = process_tickets(election_code, state)
    @votes = process_ballot_papers(election_code, state, tickets.count)
    @current_total = @votes.count
    @candidates_to_elect = candidates_to_elect
    @quota = calculate_quota
    @candidates_elected = 0
    @cur_candidate_count = @candidates.count - candidates_to_exclude.count
    @current_exhaust = 0
    @exhausted_votes = []
    @fraction_lost = 0
    @state = state
    @pending_distribution = 0
    @candidates_to_exclude = candidates_to_exclude
  end

  attr_reader :quota, :tickets, :candidates_to_elect, :state, :candidates_to_exclude
  attr_accessor :votes, :candidates, :candidates_elected, :current_exhaust, :exhausted_votes, :current_total, :cur_candidate_count, :fraction_lost, :pending_distribution

  def calculate_quota
    (@current_total / (@candidates_to_elect + 1)) + 1
  end

  def process_btl_first_preference
    puts 'Processing the BTL votes'
    bar = ProgressBar.new(current_total)
  
    votes.each do |v|
      bar.increment!

      cur_pref = 0

      candidates.count.times do |t|
        next_pref = (cur_pref + 1 + t)
        unless v.btl.count(next_pref) == 1
          v.is_exhaust = true
          v.cur_candidate = nil
          break
        end
        if candidates[v.btl.index(next_pref)].excluded || candidates[v.btl.index(next_pref)].elected
          next
        else
          v.cur_candidate = v.btl.index(next_pref)
          candidates[v.cur_candidate].cur_papers << v
          candidates[v.cur_candidate].cur_votes[0] += 1
          candidates[v.cur_candidate].transfers[1.0] += 1
          break
        end
      end
    end
  end

  def process_atl_preferences
    puts 'Processing the atl preferences'
    bar = ProgressBar.new(current_total)
    votes.each do |v|
      bar.increment!
      next if v.btl_formal

      checking = true
      v.btl = []

      atl_preference = 1
      preference = 1
      updated = false

      while checking
        box = v.atl.find_index(atl_preference)
        break if box.nil?
        break if v.atl.count(atl_preference) > 1

        tik = tickets[box]
        ticket_complete = false
        ticket_pos = 1
        until ticket_complete
          candidates.each do |c|
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
    puts 'Subtotal' unless round == 1
    puts
 
    display_candidates = candidates.sort_by { |x| x.cur_votes.last + (x.elected_order * 1000) }.reverse
    tot = 0
   
    display_candidates.each do |c|
      next if c.excluded && c.distributed

      tot += c.cur_votes.last
      puts "  Candidate #{c.surname} is on #{c.cur_votes.last} votes (#{c.cur_papers.count} ballots). #{' ## elected ' + c.elected_order.to_s + ' ##' unless c.elected == false}"
    end
    puts
    puts "#{tot} votes remaining in count. #{current_exhaust} votes have exhausted (#{fraction_lost.round} lost to fractions). #{cur_candidate_count} candidates remaining. Current Quota - #{quota}"
    puts
  end

  def print_distributed_votes(round, candidate, x)
    display_candidates = candidates.sort_by { |x| x.recent_round_count + (x.elected_order * 1000) }.reverse
    exh = 0
    exh_v = 0.0
    frac = 0
    tot = 0

    puts
    # candidate.cur_votes << candidate.cur_votes.last + (candidate.recent_round_count * x).ceil

    candidate.cur_votes << if candidate.excluded
                             candidate.cur_votes.last - candidate.transfers[x]
                           else
                             candidate.cur_votes.last + (candidate.recent_round_count * x).ceil
                           end

    display_candidates.each do |c|
      next if c.excluded || (c.elected && c.elected_round < round)

      tmp = c.recent_round_count * x
      c.cur_votes << c.cur_votes.last + tmp.floor
      c.transfers[x] += tmp.floor if c.recent_round_count > 0
      puts "	Candidate #{c.surname} received #{c.recent_round_count} votes (worth #{(c.recent_round_count * x).floor})"
      # c.transfers |= [x] if c.recent_round_count > 0
    end
  
    votes.each do |v|
      next unless v.round_last_updated == round

      if v.is_exhaust
        exh += 1
        exh_v += x
      end
    end

    self.current_exhaust += exh_v.floor

    # export(self, round, x, candidate.order)

    candidates.each do |c|
      c.recent_round_count = 0
      tot += c.cur_votes.last
    end

    frac = current_total - tot - fraction_lost - self.current_exhaust

    self.fraction_lost += frac.round
  
    puts "	Exhuasted #{exh} votes (worth #{exh_v.floor})"
    puts "	#{frac.round} lost to fractions"
    puts
  end

  def clean_tracking_pref(atl_pref, btl_pref)
    result = {}
    if atl_pref.nil?
      result['atl'] = nil
    else
      row = []
      atl_pref.each do |b|
        row << if b.nil? || b.to_s.empty?
                 nil
               else
                 b.to_i
               end
      end
      result['atl'] = row
    end

    if btl_pref.nil?
      result['btl'] = nil
    else
      row = []
      btl_pref.each do |b|
        row << if b.nil? || b.empty?
                 nil
               else
                 b.to_i
               end
      end
      result['btl'] = row
    end
    result
  end

  def print_tagged_ballot(round, tracking)
    return if tracking['atl'].nil? && tracking['btl'].nil?

    votes.each do |v|
      next unless (v.atl && v.atl == tracking['atl']) || (v.btl && v.btl == tracking['btl'])

      puts 'Your ballot-'
      puts "currently with #{candidates[v.cur_candidate].surname}. Worth #{v.value}"
      export_target(round, v.value, candidates[v.cur_candidate].surname)
      puts
      return
    end
    puts 'ballot not found'
    CSV.open('ballot_not_found.csv', 'a') do |csv|
      votes.each do |v|
        csv << v['btl']
      end
    end
  end
end
