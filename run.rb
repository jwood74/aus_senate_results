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

ballot = setup(load_in, candidates_to_elect, state)
 
round = 1
until ballot.candidates_elected == ballot.candidates_to_elect

    puts "** COUNT #{round} **"
 
    check_for_elected(ballot,round)
 
    if ballot.candidates_elected == ballot.candidates_to_elect
        break
    end

    unless round == 1
        distribute = who_to_distribute(ballot)
        distribute_votes(ballot,round,distribute)
        ballot.print_distributed_votes(round)
    end

    ballot.print_current_votes(round)
    
    round += 1
    exit if round == 3
end