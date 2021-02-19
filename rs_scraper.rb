#  try to scrape Rolling Stone site directly
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'watir'
require 'webdrivers'

require_relative 'album'

def parse_rolling_stone2012
  browser = Watir::Browser.new
  url = 'https://www.rollingstone.com/music/music-lists/500-greatest-albums-of-all-time-156826/amy-winehouse-back-to-black-2-154956/'
  broswer.goto(url)
  js_doc = browser.element(css: '.c-gallery-vertical-album__title').wait_until(&:present?)
  doc = Nokogiri::HTML(js_doc.inner_html)
  # p doc.search('.c-gallery-vertical-album__title')
  p doc
end

parse_rolling_stone2012