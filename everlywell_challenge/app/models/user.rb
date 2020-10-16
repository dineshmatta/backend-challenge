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

  def self.search(user, search)
    if search
      # Get searching users friendships
      user_friends = user.friends
      user_hash = {}

      user_friends.each do |user_friend| # dineshOutlook
        user_friend.friends.each do |friend| ## dineshrediff Dinesh
          if !user.friend_with?(friend) && user.id != friend.id
            expert_link = self.find_expert(friend, user_friend, search)
            return expert_link.length > 0 ? expert_link : []
          end
        end
      end

    end
  end

  def self.find_expert(friend, parent_friend, search)
    match_found = false
    expert_user_connection = []

    unless friend.content
      return nil
    end

    if friend.content && friend.content.match(search)
      match_found = true
      expert_user_connection.push(parent_friend.name)
      expert_user_connection.push(friend.name)
      return expert_user_connection
    elsif friend.friends.length > 0
      friend.friends.each do |frnd|
        if frnd.id != parent_friend.id && !match_found
          return self.find_expert(frnd, friend, search)
        end
      end
    end

    return expert_user_connection
  end

  private

  def init_bitly
    @bitlyClient ||= Bitly::API::Client.new(token: Rails.application.credentials.dig(:bitly_api_token))
  end

end
