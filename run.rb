require 'csv'
require 'progress_bar'
require 'pathname'

require_relative 'commands'
require_relative 'ballot'
require_relative 'candidates'

state = 'QLD'
candidates_to_elect = 12
$debug = false

download_candidates
download_results(state)

# ballot = Ballot.new(candidates_to_elect,state)

# ballot.process_btl_first_preference
# ballot.process_atl_preferences

# File.open("ballot.b","wb") {|f| f.write(Marshal.dump(ballot))}
ballot = Marshal.load(File.read('ballot.b'))

 
=begin

print_current_votes(ballot)
 
round = 0
until ballot.candidates_elected == ballot.candidates_to_elect
    puts "** ROUND #{round} **"
 
    elected = check_for_elected(ballot,round)
 
    if ballot.candidates_elected == ballot.candidates_to_elect
        break
    end
 
    if elected.count > 0
        elected.each do |e|
            distribute_votes(ballot,round,e)
            print_current_votes(ballot)
        end
    else
        lowest = find_lowest(ballot)
        distribute_votes(ballot,round,lowest)
        print_current_votes(ballot)
    end
    round += 1
end

=end