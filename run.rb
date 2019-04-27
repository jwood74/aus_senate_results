require 'csv'
require 'progress_bar'
require 'pathname'

require_relative 'commands'
require_relative 'ballot'
require_relative 'candidates'

state = 'QLD'
candidates_to_elect = 12
$debug = false
load_in = true

download_candidates
download_results(state)

ballot = setup(load_in, candidates_to_elect, state)

round = 1
puts "** COUNT #{round} **"
check_for_elected(ballot, round)
ballot.print_current_votes(round)
export(ballot, round)
round += 1
puts "** COUNT #{round} **"

until ballot.candidates_elected == ballot.candidates_to_elect

  if ballot.cur_candidate_count == (ballot.candidates_to_elect - ballot.candidates_elected)
    puts "candidaes left equal spots"
    break
  end

  distribute = who_to_distribute(ballot)
  round = distribute_votes(ballot, round, distribute)

end
