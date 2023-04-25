require 'csv'
require 'progress_bar'
require 'zip'
require 'open-uri'

require_relative 'commands'
require_relative 'ballot'
require_relative 'ballotpaper'
require_relative 'candidates'

state = 'ACT'
candidates_to_elect = 2
election_code = 27_966

## Incase certain candidates need to be excluded before the count,
## add the below-the-line id of each here. Leave empty if no exclusions.
candidates_to_exclude = [] # 62,90
## BTL ballot papers

download_candidates(election_code, state)
download_results(election_code, state)

ballot = setup(candidates_to_elect, election_code, state, candidates_to_exclude)

# tracking = ballot.clean_tracking_pref(nil, ['', '7', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '1', '2', '3', '4', '5', '6'])
tracking = ballot.clean_tracking_pref(nil, nil)

round = 1
puts "** COUNT #{round} **"
check_for_elected(ballot, round)
ballot.print_current_votes(round)
ballot.print_tagged_ballot(round, tracking)
export(ballot, round)
round += 1
puts "** COUNT #{round} **"

until ballot.candidates_elected == ballot.candidates_to_elect

  distribute = who_to_distribute(ballot, round)
  round = distribute_votes(ballot, round, distribute, tracking)

end

display_final_results(ballot)
