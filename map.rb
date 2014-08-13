require 'pry'
require './noise.rb'
require 'chunky_png'
require 'digest/md5'

class Map
  def initialize(width: width, height: height)
    @width = width
    @height = height
    @noise = Noise.new
  end

  def noise(x, y, octaves: 8, persistence: 0.5, scale: 0.04)
    @noise.octave_noise_2d(octaves, persistence, scale, x, y)
  end

  def height(x, y)
    noise = noise(x * 0.1, y * 0.1)
    normalize(noise, -1.0, 1.0)
  end

  def color(height)
    height *= 100.0

    snow = ChunkyPNG::Color.rgb(255, 255, 255)
    land1 = ChunkyPNG::Color.rgb(86, 150, 17)
    land2 = ChunkyPNG::Color.rgb(0, 100, 0)
    shore = ChunkyPNG::Color.rgb(237, 201, 175)
    water1 = ChunkyPNG::Color.rgb(0, 80, 160)
    water2 = ChunkyPNG::Color.rgb(0, 40, 90)

    distance = height
    if height >= 80
      distance = normalize(height, 80, 100)
      color1, color2 = snow, land1 # snow
    elsif height >= 65
      distance = normalize(height, 65, 80)
      color1, color2 = land1, land2 # land 2
    elsif height >= 60
      distance = normalize(height, 60, 65)
      color1, color2 = land2, shore # land 1
    elsif height >= 55
      distance = normalize(height, 55, 60)
      color1, color2 = shore, water1 # shore
    elsif height >= 50
      distance = normalize(height, 50, 55)
      color1, color2 = water1, water2 # water 1
    else
      distance = normalize(height, 0, 50)
      color1, color2 = water2, water2 # deep water
    end

    ChunkyPNG::Color.interpolate_quick(color1, color2, (distance * 255.0).floor)
  end

  def drawn
    png = ChunkyPNG::Image.new(@width, @height, ChunkyPNG::Color('white'))

    @width.times do |x|
      @height.times do |y|
        height = height(x, y)
        png[x, y] = color(height)
      end
    end

    png.save(filename, interlace: true)
  end

  def open
    `open #{filename}`
  end

  private

  def filename
    @filename ||= begin
      hash = Digest::MD5.hexdigest(Time.now.to_s)[0, 10]
      "map-#{hash}.png"
    end
  end

  def normalize(value, min, max)
    (value - min) / (max - min)
  end
end

size = 500
map = Map.new(width: size, height: size)
map.drawn
map.open
