require 'json'

module Choropleth
  class Generator
    attr_reader :grid_polys, :points, :options

    # gridJson, dataJson: GeoJSON objects
    def initialize(dataJson, gridJson, options = {})
      @options = {fields: []}.merge options

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
            break
          end
        end
      end

      # Call 'add_<field>' on each polygon, optionally with options
      @grid_polys.each do |poly|
        @options[:fields].each { |field| poly.send *(Hash === field ? ["add_#{field.keys.first}".to_sym, field.values.first] : ["add_#{field}".to_sym]) }
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
