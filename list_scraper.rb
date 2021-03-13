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
  csv_file_path = './albums_list.csv'
  save_to_csv(csv_file_path, @albums_array)
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
  # (?<!l)(?<!\.)[^\p{Letter}]+ regex for orting out Vol.x?
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

def save_to_csv(csv_file_path, array_to_save)
  CSV.open(csv_file_path, 'wb', col_sep: ',') do |csv|
    csv << ["Title", "Artist", "Year", "Ranking2003", "Ranking2012", "Ranking2020", "Ranking_Avg"]
    array_to_save.each do |album|
      csv << [album.title, album.artist, album.year, album.ranking2003, album.ranking2012, album.ranking2020, album.ranking_avg]
    end
  end
end

def load_csv
  @albums_array = []
  csv_options = {headers: :first_row, header_converters: :symbol}
  CSV.foreach('albums_list.csv', csv_options) do |row|
    row[:title] = row[:title]
    row[:artist] = row[:artist]
    row[:year] = row[:year].to_i
    row[:ranking2003] = row[:ranking2003].nil? ? nil : row[:ranking2003].to_i
    row[:ranking2012] = row[:ranking2012].nil? ? nil : row[:ranking2012].to_i
    row[:ranking2020] = row[:ranking2020].nil? ? nil : row[:ranking2020].to_i
    row[:ranking_avg] = row[:ranking_avg].to_i
    @albums_array << Album.new(row)
  end
end

def albums_cut2012
  @array_cut2012 = []
  @albums_array.each do |album|
    @array_cut2012 << album if !album.ranking2003.nil? && album.ranking2012.nil?
  end
end

def albums_added2012
  @array_add2012 = []
  @albums_array.each do |album|
    @array_add2012 << album if album.ranking2003.nil? && !album.ranking2012.nil?
  end
end

def albums_cut2020
  @array_cut2020 = []
  @albums_array.each do |album|
    @array_cut2020 << album if !album.ranking2012.nil? && album.ranking2020.nil?
  end
end

def albums_added2020
  @array_added2020 = []
  @albums_array.each do |album|
    @array_added2020 << album if album.ranking2012.nil? && !album.ranking2020.nil?
  end
end

def reentries
  @array_reenter = []
  @albums_array.each do |album|
    @array_reenter << album if !album.ranking2003.nil? && album.ranking2012.nil? && !album.ranking2020.nil?
  end
end

analyse_lists
# load_csv
# p @albums_array
reentries
csv_file_path = './albums_reentries.csv'
save_to_csv(csv_file_path, @array_reenter)

# parse_genius2020
# @albums_array = []
# parse_genius2003
# p format_albums_array
