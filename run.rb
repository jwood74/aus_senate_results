require 'rubygems'
require 'bundler/setup'
Bundler.require

require_relative 'commands'
require_relative 'ballot'
require_relative 'candidates'

state = 'QLD'
candidates_to_elect = 12

## Incase certain candidates need to be excluded before the count,
## add the below-the-line id of each here. Leave empty if no exclusions.
candidates_to_exclude = []  #62,90
## BTL ballot papers

download_candidates
download_results(state)

ballot = setup(candidates_to_elect, state, candidates_to_exclude)

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