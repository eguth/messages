require "data_mapper"

def database_uri
  ENV["DATABASE_URL"] || "sqlite3://#{File.dirname(__FILE__)}/local.db"
end

DataMapper.setup(:default, database_uri)

class Person
  include DataMapper::Resource

  property :id, Serial
  property :email, String, required: true
  property :name, String, required: true
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :messages

  def gravatar
    hash = Digest::MD5.hexdigest(email.to_s.downcase.strip)
    "https://secure.gravatar.com/avatar/#{hash}"
  end
end

class Message
  include DataMapper::Resource

  property :id, Serial
  property :body, Text
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :person
end

DataMapper.auto_migrate!
