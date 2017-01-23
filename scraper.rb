#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :members do
    noko.css('div.module_bestuur div.person').map do |person|
      fragment person => MemberSection
    end
  end
end

class MemberSection < Scraped::HTML
  field :id do
    CGI.parse(URI.parse(image).query)['fileid'].first
  end

  field :name do
    noko.css('h2').text.tidy.gsub('&eacute', 'é')
  end

  field :party do
    noko.xpath('.//th[.="Politieke partij"]/../td').text.tidy
  end

  field :email do
    noko.css('a[href*="mailto:"]/@href').text.sub('mailto:', '')
  end

  field :image do
    noko.css('div.photo img/@src').text
  end

  field :term do
    2
  end
end

url = 'http://www.parlamento.cw/nederlands/huidige-leden_3173/'
data = MembersPage.new(response: Scraped::Request.new(url: url).response).members.map(&:to_h)
# data.each { |mem| puts mem.reject { |k, v| v.to_s.empty? }.sort_by { |k, v| k }.to_h }

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
ScraperWiki.save_sqlite(%i(id term), data)
