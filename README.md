# Australian Senate Results
Determining Senate results from the provided ballot export

# Background
Following a federal election, the AEC publishes a copy of every formal ballot paper for the senate, in a CSV.
Using this data, and systems like this one, the public can recreate the senate count to determine the winners.

# Setup
+ Install the required gem files.
+ update run file with the State you are after (eg NSW, VIC, QLD)
+ Execute run.rb

# ToDo
+ optimise atl distribution
+ don't distribute if electect by exact number
+ elect all if remaining candidates equals number to elect
+ order of election if two elected with same number of votes
+ Allow a candidate to be excluded from beginning (as was the case when candidates became ineligible)
+ Pretty output of final result
+ Show output for each step of count

# Contact
jw@jaxenwood.com