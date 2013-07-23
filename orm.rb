require "data_mapper"
require "dm-timestamps"

def database_uri
  ENV["DATABASE_URL"] || "sqlite3://#{File.dirname(__FILE__)}/local.db"
end

DataMapper.setup(:default, database_uri)

class Account
  include DataMapper::Resource

  property :id, Serial
  property :subdomain, String, required: true
  property :created_at, DateTime

  has n, :messages
  has n, :people
end

class Person
  include DataMapper::Resource

  property :id, Serial
  property :email, String, required: true
  property :name, String, required: true
  property :user_id, Integer, required: true
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :messages
  belongs_to :account

  def gravatar
    hash = Digest::MD5.hexdigest(email.to_s.downcase.strip)
    "https://secure.gravatar.com/avatar/#{hash}.img"
  end
end

class Message
  include DataMapper::Resource

  property :id, Serial
  property :body, Text, required: true
  property :created_at, DateTime
  property :updated_at, DateTime
  property :parent_id, Integer

  belongs_to :person
  belongs_to :account
  belongs_to :parent, self

  has n, :children, self, :child_key => [:parent_id]
end

DataMapper.auto_upgrade!
