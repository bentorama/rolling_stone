# Album class definition
class Album
  attr_reader :title, :artist, :year, :ranking2003
  attr_accessor :ranking2012, :ranking2020, :ranking_avg

  def initialize(attributes = {})
    @title = attributes[:title]
    @artist = attributes[:artist]
    @year = attributes[:year]
    @ranking2003 = attributes[:ranking2003] || nil
    @ranking2012 = attributes[:ranking2012] || nil
    @ranking2020 = attributes[:ranking2020] || nil
    @ranking_avg = attributes[:ranking_avg] || nil
  end
end
