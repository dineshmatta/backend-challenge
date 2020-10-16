require 'open-uri'
require 'nokogiri'

class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: true }

  after_save :fetch_profile, if: :website_url
  before_save :init_bitly

  def init_bitly
    @bitlyClient ||= Bitly::API::Client.new(token: Rails.application.credentials.dig(:bitly_api_token))
  end

  def fetch_profile
    begin
      logger.info '****bitlyClient short url***'
      logger.info @bitlyClient
      # Rails.application.credentials.dig(:bitly_api_token)
      # uri = Addressable::URI.parse(website)
      # url = "http://#{website}" if(!uri.scheme)
      #Setp1 - Fetch and Parse website page
      document = Nokogiri::HTML.parse(open(website_url))
      # update(:website => {:h1 => document.h1, :h2 => document.h2, :h3 => document.h3} )
      ## step 2 - Extract content from website - h1, h2 and h3 tags
      contentHtml = document.css('h1, h2, h3').map(&:text).join("<br/>") if document;

      ## step 3 - shorten the url
      bitlink = @bitlyClient.shorten(long_url: website_url)
      logger.info '****logging short url***'
      logger.info bitlink.link

      update(:content => contentHtml, :short_url => bitlink.link) if contentHtml
    rescue StandardError => e
      puts "Rescued: #{e.inspect}"
    end
  end

end
