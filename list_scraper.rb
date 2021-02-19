require 'nokogiri'
require 'open-uri'
require 'csv'
require 'active_support/inflector'

require_relative 'album'

def analyse_lists
  @albums_array = []
  parse_genius2003
  # p @albums_array
  parse_genius2012
  parse_genius2020
  calculate_average
  sort_albums
  save_to_csv
  p @albums_array
  p @albums_array.size
end

def parse_genius2003
  url = '2003.html'
  doc = Nokogiri::HTML(open(url), nil, 'utf-8')
  list_string = doc.search('.lyrics').text.strip
  # puts doc.search('.lyrics').text.strip.gsub!(/\n\n/, "\n")
  rank = 1
  list_string.each_line do |line|
    title = line.match(/\s(.+)\s\((\d{4})\)\sby\s(.+)/)[1]
    artist = line.match(/\s(.+)\s\((\d{4})\)\sby\s(.+)/)[3]
    year = line.match(/\s(.+)\s\((\d{4})\)\sby\s(.+)/)[2]
    @albums_array << Album.new(title: title, artist: artist, year: year, ranking2003: rank)
    rank += 1
  end
end

def parse_genius2012
  url = '2012.html'
  doc = Nokogiri::HTML(open(url), nil, 'utf-8')
  # list_string = doc.search('.lyrics').text.strip
  list_string = doc.search('.lyrics').text.strip.gsub!(/\n\n/, "\n")
  rank = 1
  list_string.each_line do |line|
    title = line.match(/\.\s?(.+)\s\((\d{4})\)\sby\s(.+)/)[1]
    artist = line.match(/\.\s?(.+)\s\((\d{4})\)\sby\s(.+)/)[3]
    year = line.match(/\.\s?(.+)\s\((\d{4})\)\sby\s(.+)/)[2]
    contained = false
    # iterate over @albums_array and check if title and artist already exist
    # if the album exists update the 2012 rank
    # if the album doesn't exist create a new instance of Album and push to the array
    @albums_array.each do |album|
      album_artist_formatted = ActiveSupport::Inflector.transliterate(album.artist.downcase.gsub(/&/, 'and').gsub(/[^\p{Letter}]+/, ''))
      artist_formatted = ActiveSupport::Inflector.transliterate(artist.downcase.gsub(/&/, 'and').gsub(/[^\p{Letter}]+/, ''))
      album_title_formatted = ActiveSupport::Inflector.transliterate(album.title.downcase.gsub(/&/, 'and').gsub(/[^\p{Letter}]+/, ''))
      title_formatted = ActiveSupport::Inflector.transliterate(title.downcase.gsub(/&/, 'and').gsub(/[^\p{Letter}]+/, ''))
      title_match = album_title_formatted.include?(title_formatted) || title_formatted.include?(album_title_formatted)
      album_match = album_artist_formatted.include?(artist_formatted) || artist_formatted.include?(album_artist_formatted)
      if  title_match && album_match
        album.ranking2012 = rank
        contained = true
      end
    end
    @albums_array << Album.new(title: title, artist: artist, year: year, ranking2012: rank) if contained == false
    rank += 1
  end
end

def parse_genius2020
  url = '2020.html'
  doc = Nokogiri::HTML(open(url), nil, 'utf-8')
  list_string = doc.search('.lyrics').text.strip
  rank = 1
  list_string.each_line do |line|
    artist = line.match(/\|(.+)\|(.+)\|\s(\d{4})/)[1].strip
    title = line.match(/\|(.+)\|(.+)\|\s(\d{4})/)[2].strip
    year = line.match(/\|(.+)\|(.+)\|\s(\d{4})/)[3]
    contained = false
    @albums_array.each do |album|
      album_artist_formatted = ActiveSupport::Inflector.transliterate(album.artist.downcase.gsub(/&/, 'and').gsub(/[^\p{Letter}]+/, ''))
      artist_formatted = ActiveSupport::Inflector.transliterate(artist.downcase.gsub(/&/, 'and').gsub(/[^\p{Letter}]+/, ''))
      album_title_formatted = ActiveSupport::Inflector.transliterate(album.title.downcase.gsub(/&/, 'and').gsub(/[^\p{Letter}]+/, ''))
      title_formatted = ActiveSupport::Inflector.transliterate(title.downcase.gsub(/&/, 'and').gsub(/[^\p{Letter}]+/, ''))
      title_match = album_title_formatted.include?(title_formatted) || title_formatted.include?(album_title_formatted)
      album_match = album_artist_formatted.include?(artist_formatted) || artist_formatted.include?(album_artist_formatted)
      if title_match && album_match
        album.ranking2020 = rank
        contained = true
      end
    end
    @albums_array << Album.new(title: title, artist: artist, year: year, ranking2020: rank) if contained == false
    rank += 1
  end
end

def calculate_average
  @albums_array.each do |album|
    album_array = [album.ranking2003, album.ranking2012, album.ranking2020]
    album_array.compact!
    album.ranking_avg = (album_array.sum / album_array.size.to_f).round(2)
  end
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

