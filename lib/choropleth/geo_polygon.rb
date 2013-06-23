module Choropleth
  class GeoPolygon
    attr_reader :verts, :bbox, :data

    # poly: entire Feature. Does not support rings, first vertex must be same as last
    def initialize(poly)
      @verts = []
      poly['geometry']['coordinates'].each do |ring|
        ring.each do |coords|
          @verts << [coords[0], coords[1]]
        end
      end
      @bbox = get_bounding_box
      @data = poly['properties']
    end

    # data: {key: value, ...}
    def add_data(data)
      data.each do |field, value|
        @data[field] = value
      end
    end

    def to_json
      {
        "type" => "Feature", 
        "properties" => @data, 
        "geometry" => { 
          "type" => "Polygon", 
          "coordinates" => [@verts]
        }
      }
    end

    def contains_point?(point)
      point = point['geometry']['coordinates']
      return false if not point_in_bounding_box?(point)
      intersections = 0
      (0...@verts.size - 1).each do |i|
        if crosses_ray?(point, @verts[i], @verts[i + 1])
          if point[0] < interpolate_x_coord(point, @verts[i], @verts[i + 1])
            intersections += 1
          end
        end
      end
      return intersections % 2 == 1
    end

    def crosses_ray?(point, ep1, ep2)
      if ep1[1] < ep2[1] # upward
        return (point[1] >= ep1[1] and point[1] < ep2[1])
      elsif ep1[1] > ep2[1] # downward
        return (point[1] >= ep2[1] and point[1] < ep1[1])
      end
      false
    end

    def interpolate_x_coord(point, ep1, ep2)
      return ep1[0] if ep1[0] == ep2[0]
      ep1, ep2 = ep2, ep1 if ep2[0] < ep1[0] # ep2 must be the rightmost point
      m = (ep2[1] - ep1[1]).to_f / (ep2[0] - ep1[0])
      b = ep2[1].to_f - (m * ep2[0])
       (point[1] - b).to_f / m
    end

    def get_bounding_box
      minX = maxX = @verts[0][0]
      minY = maxY = @verts[0][1]
      @verts.each do |vert|
        minX = vert[0] if vert[0] < minX
        maxX = vert[0] if vert[0] > maxX
        minY = vert[1] if vert[1] < minY
        maxY = vert[1] if vert[1] > maxY
      end
      {bottomLeft: [minX, minY], topRight: [maxX, maxY]}
    end

    def point_in_bounding_box?(point)
      return true if (point[0] >= @bbox[:bottomLeft][0] and point[0] <= @bbox[:topRight][0]) and 
                (point[1] >= @bbox[:bottomLeft][1] and point[1] <= @bbox[:topRight][1])
      false
    end

    def area
      area = 0
      (0...@verts.size - 1).each do |i|
        area += (@verts[i+1][1] + @verts[i][1]) / 2.0 * (@verts[i+1][0] - @verts[i][0])
      end
      area.abs
    end
  end
end
