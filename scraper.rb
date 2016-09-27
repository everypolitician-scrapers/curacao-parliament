#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'csv'
require 'scraperwiki'
require 'pry'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('div.module_bestuur div.person').each do |person|
    image = person.css('div.photo img/@src').text

    data = {
      id: CGI.parse(URI.parse(image).query)['fileid'].first,
      name: person.css('h2').text.tidy.gsub('&eacute','é'),
      party: person.xpath('.//th[.="Politieke partij"]/../td').text.tidy,
      email: person.css('a[href*="mailto:"]/@href').text.sub('mailto:',''),
      image: URI.join(url, image).to_s,
      term: 2,
    }
    ScraperWiki.save_sqlite([:id, :term], data)
  end
end

term = {
  id: '2',
  name: '2nd Curaçaoan Estates',
  start_date: '2012-09-11',
  source: 'http://www.parlamento.cw/parliament/s4/',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

scrape_list('http://www.parlamento.cw/nederlands/huidige-leden_3173/')
