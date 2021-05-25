require 'csv'

# require_relative 'list_scraper'
require_relative 'album'

def load_csv(csv_file_path, albums_array)
  csv_options = {headers: :first_row, header_converters: :symbol}
  CSV.foreach(csv_file_path, csv_options) do |row|
    row[:title] = row[:title]
    row[:artist] = row[:artist]
    row[:year] = row[:year].to_i
    row[:ranking2003] = row[:ranking2003].nil? ? nil : row[:ranking2003].to_i
    row[:ranking2012] = row[:ranking2012].nil? ? nil : row[:ranking2012].to_i
    row[:ranking2020] = row[:ranking2020].nil? ? nil : row[:ranking2020].to_i
    row[:ranking_avg] = row[:ranking_avg].to_i
    albums_array << Album.new(row)
  end
end

def save_to_csv(csv_file_path, array_to_save)
  CSV.open(csv_file_path, 'wb', col_sep: ',') do |csv|
    csv << ["Title", "Artist", "Year", "Ranking2003", "Ranking2012", "Ranking2020", "Ranking_Avg"]
    array_to_save.each do |album|
      csv << [album.title, album.artist, album.year, album.ranking2003, album.ranking2012, album.ranking2020, album.ranking_avg]
    end
  end
end

def find_duplicate_ranks
  albums = []
  rankings2012 = []
  rankings2020 = []
  duplicates = []
  load_csv('albums_list_202105241717.csv', albums)
  # albums.count
  # albums.each { |album| puts album.ranking2012 }
  albums.each do |album|
    rankings2012 << album.ranking2012
    rankings2020 << album.ranking2020
  end
  duplicate_2012 = find_one_using_hash_map(rankings2012)
  duplicate_2020 = find_one_using_hash_map(rankings2020)
  albums.each do |album|
    if duplicate_2012.include?(album.ranking2012) || duplicate_2020.include?(album.ranking2020)
      duplicates << album
    end
  end
  time = Time.new.strftime("%Y%m%d%H%M")
  csv_file_path = "./duplicate_rankings_#{time}.csv"
  save_to_csv(csv_file_path, duplicates)
end

def find_one_using_hash_map(array)
  array.compact!
  map = {}
  dup = []
  array.each do |v|
    map[v] = (map[v] || 0) + 1

    if map[v] > 1
      dup << v
      # break
    end
  end

  return dup
end

def compare_arrays
  array1 = []
  array2 = []
  load_csv('albums_list_202105241703.csv', array1)
  load_csv('albums_list_202104142226.csv', array2)
  # p array1[522]
  # p array2[0]
  unique_array = unique_albums(array1, array2)
  # p unique_array
end

def unique_albums(array1, array2)
  unique_array = []
  not_unique = false
  array1.each do |album1|
    not_unique = false
    array2.each do |album2|
      # puts "Album1: #{album1.title}"
      # puts "Album2: #{album2.title}"
      # puts "Artist1: #{album1.artist}"
      # puts "Artist2: #{album2.artist}"
      # puts "not_unique #{not_unique}"
      not_unique = true if album1.title == album2.title && album1.artist == album2.artist
      # puts "not_unique #{not_unique}"
    end
    # puts "NOT_UNIQUE #{not_unique}"
    # p not_unique
    unique_array << album1 if not_unique == false
  end
  p unique_array
  time = Time.new.strftime("%Y%m%d%H%M")
  csv_file_path = "./unique_albums_#{time}.csv"
  save_to_csv(csv_file_path, unique_array)
end

# compare_arrays
find_duplicate_ranks
