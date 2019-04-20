require 'csv'
require 'progress_bar'
require 'pathname'

require_relative 'commands'
require_relative 'ballot'
require_relative 'candidates'

state = 'QLD'
candidates_to_elect = 12
$debug = false
load_in = false

download_candidates
download_results(state)

ballot = setup(load_in)

ballot.print_first_preference
 
round = 0
until ballot.candidates_elected == ballot.candidates_to_elect
    round += 1
    puts "** COUNT #{round} **"
 
    ballot.candidates_to_distribute << check_for_elected(ballot,round)

    next if round == 1
 
    if ballot.candidates_elected == ballot.candidates_to_elect
        break
    end

    if ballot.candidates_to_distribute.count > 0
        e = ballot.candidates_to_distribute.delete_at(0)
        distribute_votes(ballot,round,e)
        ballot.print_current_votes
        ballot.candidates_to_distribute << check_for_elected(ballot,round)
    else
        lowest = find_lowest(ballot)
        distribute_votes(ballot,round,lowest)
        ballot.print_current_votes
    end
    exit if round == 3
end