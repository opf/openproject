require 'sqlite3'
require 'dm-core'
require 'dm-core/support/logger'
require 'dm-migrations'

DataMapper.setup :default, 'sqlite3::memory:'

# Define models
class Animal
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :notes, Text
 
  def self.setup
    Animal.create(:name => 'Dog', :notes => "Man's best friend")
    Animal.create(:name => 'Cat', :notes => "Woman's best friend")
    Animal.create(:name => 'Lion', :notes => 'King of the Jungle')
  end
end

class Ownership
  include DataMapper::Resource

  belongs_to :animal, :key => true
  belongs_to :human, :key => true

  def self.setup
  end
end

class Human
  include DataMapper::Resource

  property :id, Serial
  property :name, String

  has n, :ownerships
  has 1, :pet, :model => 'Animal', :through => :ownerships, :via => :animal

  def self.setup
  end
end

# Load fixtures
[Animal, Ownership, Human].each do |klass|
  klass.auto_migrate!
  klass.setup
end

if 'irb' == $0
  DataMapper.logger.set_log($stdout, :debug)
  DataMapper.logger.auto_flush = true
end
