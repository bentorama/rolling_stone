require 'csv'

require_relative 'album'

def load_csv(csv_file_path, albums_array)
  csv_options = {headers: :first_row, header_converters: :symbol}
  CSV.foreach(csv_file_path, csv_options) do |row|
    albums_array << Album.new(title: row[:title], artist: row[:artist])
  end
end

def compare_arrays
  array1 = []
  array2 = []
  load_csv('albums_list.csv', array1)
  load_csv('albums_list_1.csv', array2)
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
    p not_unique
    unique_array << album1 if not_unique == false
  end
  p unique_array
end

compare_arrays
