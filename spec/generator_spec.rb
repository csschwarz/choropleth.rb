require "spec_helper"

def objectWithCoords(objType, coords)
  JSON.parse({
    type: "Feature",
    properties: {
    test1: true,
    test2: false
  },
    geometry: {
    type: objType,
    coordinates: coords
  }
  }.to_json)
end

# Setup

dataGeoJson = JSON.generate({
  "type" => "FeatureCollection",
  "features" => [
    objectWithCoords('Point', [3, 3]), # 0
    objectWithCoords('Point', [2, 3]), # 0
    objectWithCoords('Point', [13, 12]), # 4
    objectWithCoords('Point', [5, 19]), # 1
    objectWithCoords('Point', [11, 5]), # 2
    objectWithCoords('Point', [10, 10]), # 2
    objectWithCoords('Point', [15, 16]), # 3
    objectWithCoords('Point', [16, 14]), # 3
    objectWithCoords('Point', [15, 13]), # 4
    objectWithCoords('Point', [13, 10]), # 4
    objectWithCoords('Point', [16, 11]), # 4
    objectWithCoords('Point', [10, 15]), # 1
    objectWithCoords('Point', [6, 12]), # 1
    objectWithCoords('Point', [0, 0]), # x
    objectWithCoords('Point', [8, 19]), # x
    objectWithCoords('Point', [10, 18]), # x horizontal line
    objectWithCoords('Point', [30, 18]), # x
  ]
})

gridGeoJson = JSON.generate({
  "type" => "FeatureCollection",
  "features" => [
    objectWithCoords('Polygon', [[[2,2],[2,5],[5,5],[5,2],[2,2]]]), #2 points
    objectWithCoords('Polygon', [[[2,5],[1,6],[3,18],[5,22],[8,18],[14,18],[13,12],[8,13],[7,15],[5,5],[2,5]]]), #3
    objectWithCoords('Polygon', [[[5,2],[5,5],[7,15],[8,13],[13,12],[12,10],[17,9],[12,1],[5,2]]]), #2
    objectWithCoords('Polygon', [[[13,12],[14,18],[17,18],[17,13],[15,14],[13,12]]]), #2
    objectWithCoords('Polygon', [[[13,12],[15,14],[17,13],[17,9],[12,10],[13,12]]]) #4
  ]
})

# Tests

describe Choropleth::Generator do 
  context "with default options" do
    before(:all) do
      @generator = Choropleth::Generator.new(dataGeoJson, gridGeoJson).generate
    end

    it "should load all grid features and point data" do
      @generator.points.size.should eq 17
      @generator.grid_polys.size.should eq 5
    end

    it "should generate a choropleth with accurate counts" do
      counts = []
      @generator.grid_polys.each do |poly|
        counts << poly.data['count']
      end
      counts.should eq [2, 3, 2, 2, 4]
    end
  end

  context "with density mode enabled" do
    before do
      @generator = Choropleth::Generator.new(dataGeoJson, gridGeoJson, :fields => ["density"]).generate
    end

    it "should add an area attribute" do
      @generator.grid_polys.each do |poly|
        poly.data["area"].should_not be_nil
      end
    end
    
    it "should calculate the density of each polygon" do
      densities = []
      @generator.grid_polys.each do |poly|
        densities << poly.data["density"]
      end
      expected = [0.222, 0.030, 0.021, 0.125, 0.242]
      (0..4).each do |i|
        (densities[i] - expected[i]).abs.should be <= 0.005
      end
    end
  end
end
