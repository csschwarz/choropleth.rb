require 'json'

module Choropleth
  class Generator
    attr_reader :grid_polys, :points, :options

    # gridJson, dataJson: GeoJSON objects
    def initialize(dataJson, gridJson, options = {})
      @options = {mode: "count"}.merge options

      data = JSON.parse(dataJson)
      @points = data['features']

      grid = JSON.parse(gridJson)
      @grid_polys = []
      grid['features'].each do |f|
        poly = GeoPolygon.new(f)
        poly.add_data("count" => 0) 
        @grid_polys << poly
      end
      self
    end

    def generate
      @points.each do |point|
        @grid_polys.each do |poly|
          if poly.contains_point?(point)
            poly.data["count"] += 1
            poly.add_data("area" => poly.area) if @options[:mode] == "density" and poly.data["area"].nil?
            break
          end
        end
      end
      if @options[:mode] == "density"
        @grid_polys.each { |poly| poly.add_data("density" => poly.data["count"] / poly.data["area"].to_f) }
      end
      self
    end

    def save(filename)
      geoJson = {"type" => "FeatureCollection", "features" => []}

      @grid_polys.each { |poly| geoJson['features'] << poly.to_json }

      File.open(filename, 'w') do |file|
        file.write JSON.generate(geoJson)
      end
    end

  end
end
