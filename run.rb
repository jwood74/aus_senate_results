require 'rubygems'
require 'bundler/setup'
Bundler.require

require_relative 'commands'
require_relative 'ballot'
require_relative 'candidates'

state = 'VIC'
candidates_to_elect = 6
election_code = 24310

## Incase certain candidates need to be excluded before the count,
## add the below-the-line id of each here. Leave empty if no exclusions.
candidates_to_exclude = []  #62,90
## BTL ballot papers

download_candidates(election_code,state)
download_results(election_code,state)

ballot = setup(candidates_to_elect,election_code,state, candidates_to_exclude)

tracking = ballot.clean_tracking_pref([],nil)

round = 1
puts "** COUNT #{round} **"
check_for_elected(ballot, round)
ballot.print_current_votes(round)
ballot.print_tagged_ballot(round,tracking)
export(ballot, round)
round += 1
puts "** COUNT #{round} **"

until ballot.candidates_elected == ballot.candidates_to_elect

  distribute = who_to_distribute(ballot,round)
  round = distribute_votes(ballot, round, distribute,tracking)

end

display_final_results(ballot)