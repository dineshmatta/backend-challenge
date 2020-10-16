require 'open-uri'
require 'nokogiri'

class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: true }

  has_many :friendships, :foreign_key => "user_id", :class_name => "Friendship"
  has_many :friends, :through => :friendships

  after_save :fetch_profile, if: :website_url
  before_save :init_bitly

  scope :friend_with, ->( other ) do
    other = other.id if other.is_a?( User )
    joins(:friendships).where( '(friendships.user_id = users.id AND friendships.friend_id = ?) OR (friendships.user_id = ? AND friendships.friend_id = users.id)', other, other ).includes( :frienships )
  end

  def friend_with?( other )
    User.where( id: id ).friend_with( other ).any?
  end

  def befriend(user)
    unless self.friend_with?(user)
      self.friends << user
      user.friends << self
    else
      raise "Friendship already exist"
    end
  end

  def fetch_profile
    begin
      #step 1- Get the document using Nokogiri
      document = Nokogiri::HTML.parse(URI.open(website_url))

      # step 2 - Extract h1-h3 tags
      contentHtml = document.css('h1, h2, h3').map(&:text).join("<br/>") if document;

      # step 3 - short the URL using bitly
      bitlink = @bitlyClient.shorten(long_url: website_url)

      update(:content => contentHtml, :short_url => bitlink.link) if contentHtml
    rescue StandardError => e
      puts "Rescued: #{e.inspect}"
    end
  end

  ## Class methods
  def self.all_except(user)
    where.not(id: user)
  end

  private

  def init_bitly
    @bitlyClient ||= Bitly::API::Client.new(token: Rails.application.credentials.dig(:bitly_api_token))
  end

end
