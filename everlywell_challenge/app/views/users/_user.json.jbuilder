json.extract! user, :id, :email, :name, :website_url, :short_url, :content, :created_at, :updated_at
json.url user_url(user, format: :json)
