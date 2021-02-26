require 'nokogiri'
require 'open-uri'
require 'csv'
require 'active_support/inflector'
require 'benchmark'

require_relative 'album'

def analyse_lists
  @albums_array = []
  parse_genius2003
  p @albums_array.size
  format_albums_array
  # p @albums_array
  parse_genius2012
  p @albums_array.size
  format_albums_array
  # p elapsed2012
  # parse_genius2012
  parse_genius2020
  elvis_sun_sessions
  p @elvis_albums
  calculate_average
  sort_albums
  save_to_csv
  # p @albums_array
  p @albums_array.size
end

def test_lists
  @albums_array = []
  parse_genius2003
  format_albums_array
  p @albums_array.size
  p @formatted_albums_array.size
  p @albums_array[9]
  p @formatted_albums_array[9]
  parse_genius2012
  format_albums_array
  p @albums_array.size
  p @formatted_albums_array.size
  p @albums_array[9]
  p @formatted_albums_array[9]
end

def parse_genius2003
  doc = Nokogiri::HTML(open('2003.html'), nil, 'utf-8')
  list_string = doc.search('.lyrics').text.strip
  rank = 1
  list_string.each_line do |line|
    title = line.match(/\s(.+)\s\((\d{4})\)\sby\s(.+)/)[1].gsub(/"/, '')
    artist = line.match(/\s(.+)\s\((\d{4})\)\sby\s(.+)/)[3]
    year = line.match(/\s(.+)\s\((\d{4})\)\sby\s(.+)/)[2]
    @albums_array << Album.new(title: title, artist: artist, year: year, ranking2003: rank)
    rank += 1
  end
end

def format_albums_array
  @formatted_albums_array = []
  @albums_array.each do |album|
    album_artist_formatted = ActiveSupport::Inflector.transliterate(album.artist.downcase.gsub(/&/, 'and').gsub(/the/, '').gsub(/[^\p{Letter}]+/, ''))
    album_title_formatted = ActiveSupport::Inflector.transliterate(album.title.downcase.gsub(/&/, 'and').gsub(/the/, '').gsub(/[^\p{Letter}]+/, ''))
    @formatted_albums_array << [album_artist_formatted, album_title_formatted]
  end
  @formatted_albums_array
end

def parse_genius2012
  doc = Nokogiri::HTML(open('2012.html'), nil, 'utf-8')
  # list_string = doc.search('.lyrics').text.strip
  list_string = doc.search('.lyrics').text.strip.gsub!(/\n\n/, "\n")
  rank = 1
  list_string.each_line do |line|
    match = line.match(/\.\s?(.+)\s\((\d{4})\)\sby\s(.+)/)
    title = match[1]
    artist = match[3]
    year = match[2]
    artist_formatted = formatter(artist)
    title_formatted = formatter(title)
    contained = false
    # iterate over @albums_array and check if title and artist already exist
    # if the album exists update the 2012 rank
    # if the album doesn't exist create a new instance of Album and push to the array
    @formatted_albums_array.each_with_index do |album, index|
      title_match = album[1].include?(title_formatted) || title_formatted.include?(album[1])
      album_match = album[0].include?(artist_formatted) || artist_formatted.include?(album[0])
      if title_match && album_match
        @albums_array[index].ranking2012 = rank
        contained = true
      end
    end
    @albums_array << Album.new(title: title, artist: artist, year: year, ranking2012: rank) if contained == false
    rank += 1
  end
end

def parse_genius2020
  doc = Nokogiri::HTML(open('2020.html'), nil, 'utf-8')
  list_string = doc.search('.lyrics').text.strip
  rank = 1
  list_string.each_line do |line|
    match = line.match(/\|(.+)\|(.+)\|\s(\d{4})/)
    artist = match[1].strip
    title = match[2].strip
    year = match[3]
    artist_formatted = formatter(artist)
    title_formatted = formatter(title)
    contained = false
    @formatted_albums_array.each_with_index do |album, index|
      title_match = album[1].include?(title_formatted) || title_formatted.include?(album[1])
      album_match = album[0].include?(artist_formatted) || artist_formatted.include?(album[0])
      if title_match && album_match
        @albums_array[index].ranking2020 = rank
        contained = true
      end
    end
    @albums_array << Album.new(title: title, artist: artist, year: year, ranking2020: rank) if contained == false
    rank += 1
  end
end

def formatter(artist_or_title)
  artist_or_title = artist_or_title.downcase.gsub(/&/, 'and').gsub(/the/, '').gsub(/[^\p{Letter}]+/, '')
  ActiveSupport::Inflector.transliterate(artist_or_title)
end

def calculate_average
  @albums_array.each do |album|
    album_array = [album.ranking2003, album.ranking2012, album.ranking2020]
    album_array.compact!
    album.ranking_avg = (album_array.sum / album_array.size.to_f).round(2)
  end
end

def elvis_sun_sessions
  @elvis_albums = []
  @albums_array.each_with_index do |album, index|
    @elvis_albums << [index, album] if album.title.downcase.include?('sun') && album.artist == 'Elvis Presley'
  end
  elvis_rankings
  @albums_array.delete_at(@elvis_albums[1][0])
end

def elvis_rankings
  @elvis_albums[0][1].ranking2003 = @elvis_albums[1][1].ranking2003 if @elvis_albums[0][1].ranking2003.nil?
  @elvis_albums[0][1].ranking2012 = @elvis_albums[1][1].ranking2012 if @elvis_albums[0][1].ranking2012.nil?
  @elvis_albums[0][1].ranking2020 = @elvis_albums[1][1].ranking2020 if @elvis_albums[0][1].ranking2020.nil?
end

def sort_albums
  @albums_array.sort_by!(&:ranking_avg)
end

def save_to_csv
  csv_file_path = "./albums_list.csv"
  CSV.open(csv_file_path, 'wb', col_sep: ',') do |csv|
    csv << ["Title", "Artist", "Year", "Ranking 2003", "Ranking 2012", "Ranking 2020", "Average Ranking"]
    @albums_array.each do |album|
      csv << [album.title, album.artist, album.year, album.ranking2003, album.ranking2012, album.ranking2020, album.ranking_avg]
    end
  end
end
analyse_lists
# parse_genius2020
# @albums_array = []
# parse_genius2003
# p format_albums_array
