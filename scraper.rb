#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'csv'
require 'scraperwiki'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('div.twelve a[href*="/members/"]/@href').map(&:text).uniq.each do |link|
    mp_url = URI.join url, link
    mp = noko_for(mp_url)
    box = mp.css('#memberdetails')

    frakshon = box.xpath('.//label[contains(text(),"Frakshon")]/following-sibling::a').text
    party, party_id = frakshon.match(/(.*) \((.*)\)/).captures

    data = { 
      id: mp_url.to_s.split('/').last,
      name: box.css('h3').text.strip.gsub('&eacute','é'),
      party: party,
      party_id: party_id,
      email: box.css('a[href*="mailto:"]/@href').text.sub('mailto:',''),
      facebook: box.css('a[href*="facebook.com"]/@href').text,
      twitter: box.css('a[href*="twitter.com"]/@href').text,
      image: box.css('img.memberimage/@src').text,
      term: 2,
      source: url,
    }
    data[:image] = URI.join(mp_url, data[:image]).to_s unless data[:image].to_s.empty?
    puts data
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end

term = {
  id: '2',
  name: '2nd Curaçaoan Estates',
  start_date: '2012',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

scrape_list('http://www.parlamento.cw/parliament/s11/')
