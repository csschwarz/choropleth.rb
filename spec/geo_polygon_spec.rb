require "spec_helper"

describe Choropleth::GeoPolygon do
  before(:all) do
    @diamond = objectWithCoords('Polygon', [[[2, 0], [4, 2], [2, 4], [0, 2], [2, 0]]])
    @claw = objectWithCoords('Polygon', [[[4, 4], [9, 5], [6, 7], [7, 8], [8, 6], [9, 10], [4, 12], [2, 7], [4, 4]]])
    @diamondPoly = Choropleth::GeoPolygon.new(@diamond)
    @clawPoly = Choropleth::GeoPolygon.new(@claw)
  end

  it "initializes with all vertices" do
  	expect(@diamondPoly.verts.size).to eq 5
    expect(@clawPoly.verts.size).to eq 9
  end

  it "gets its bounding box" do
  	@diamondPoly.bbox.should eq ({bottomLeft: [0, 0], topRight: [4, 4]})
    @clawPoly.bbox.should eq ({bottomLeft: [2, 4], topRight: [9, 12]})
  end

  it "takes GeoJSON properties as data attributes" do
    @diamondPoly.data.should eq ({"test1" => true, "test2" => false})

    @diamondPoly.add_data({"count" => 3})

    @diamondPoly.data["count"].should eq 3
  end

  it "calculates its area" do
    @diamondPoly.area.should eq 8
    @clawPoly.area.should eq 36
  end

  it "determines that external points outside the bounding box are outside it" do
  	point = objectWithCoords("Point", [0, 5])
  	@diamondPoly.contains_point?(point).should eq false

    point2 = objectWithCoords("Point", [1, 4])
    @clawPoly.contains_point?(point2).should eq false
  end

  it "determines that external points inside the bounding box are outside it" do
  	point = objectWithCoords("Point", [0.5, 1])
  	@diamondPoly.contains_point?(point).should eq false

    point2 = objectWithCoords("Point", [7, 7])
    @clawPoly.contains_point?(point2).should eq false
  end

  it "determines that internal points are inside it" do
  	point = objectWithCoords("Point", [2, 2])
  	@diamondPoly.contains_point?(point).should eq true

    point2 = objectWithCoords("Point", [8, 7])
    @clawPoly.contains_point?(point2).should eq true
  end

  it "determines that points exactly on its border are inside it" do
    point = objectWithCoords("Point", [1, 3])
    @diamondPoly.contains_point?(point).should eq true

    point2 = objectWithCoords("Point", [7.5, 7])
    @clawPoly.contains_point?(point2).should eq true
  end

  it "determines that points exactly on a vertex are inside it" do
    point = objectWithCoords("Point", [4, 2])
    @diamondPoly.contains_point?(point)

    point2 = objectWithCoords("Point", [4, 4])
    @clawPoly.contains_point?(point2)
  end
end

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
