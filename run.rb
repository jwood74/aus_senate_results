require 'csv'
require 'progress_bar'
require 'pathname'

require_relative 'commands'
require_relative 'ballot'
require_relative 'candidates'

state = 'QLD'
candidates_to_elect = 12

download_candidates
download_results(state)

ballot = setup(candidates_to_elect, state)

round = 1
puts "** COUNT #{round} **"
check_for_elected(ballot, round)
ballot.print_current_votes(round)
export(ballot, round)
round += 1
puts "** COUNT #{round} **"

until ballot.candidates_elected == ballot.candidates_to_elect

  distribute = who_to_distribute(ballot,round)
  round = distribute_votes(ballot, round, distribute)

end

display_final_results(ballot)