require 'json'
require_relative 'choropleth'

if ARGV.size < 3
	puts "USAGE: choropleth datafile gridfile outfile"
	puts "datafile and gridfile must be valid GeoJSON FeatureCollections"
	exit
end

data = File.open(ARGV[0], 'r').read
grid = File.open(ARGV[1], 'r').read
outfile = ARGV[2]

puts "Generating choropleth at #{outfile}..."

Choropleth.new(data, grid).generate.save(outfile)

puts "Done!"