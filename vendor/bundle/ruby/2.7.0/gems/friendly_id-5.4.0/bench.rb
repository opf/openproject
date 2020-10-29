require File.expand_path("../test/helper", __FILE__)
require "ffaker"

N = 10000

def transaction
  ActiveRecord::Base.transaction { yield ; raise ActiveRecord::Rollback }
end

class Array
  def rand
    self[Kernel.rand(length)]
  end
end

Book = Class.new ActiveRecord::Base

class Journalist < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged
end

class Manual < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :history
end

class Restaurant < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :finders
end


BOOKS       = []
JOURNALISTS = []
MANUALS     = []
RESTAURANTS = []

100.times do
  name = FFaker::Name.name
  BOOKS       << (Book.create! :name => name).id
  JOURNALISTS << (Journalist.create! :name => name).friendly_id
  MANUALS     << (Manual.create! :name => name).friendly_id
  RESTAURANTS << (Restaurant.create! :name => name).friendly_id
end

ActiveRecord::Base.connection.execute "UPDATE manuals SET slug = NULL"

Benchmark.bmbm do |x|
  x.report 'find (without FriendlyId)' do
    N.times {Book.find BOOKS.rand}
  end

  x.report 'find (in-table slug)' do
    N.times {Journalist.friendly.find JOURNALISTS.rand}
  end

  x.report 'find (in-table slug; using finders module)' do
    N.times {Restaurant.find RESTAURANTS.rand}
  end

  x.report 'find (external slug)' do
    N.times {Manual.friendly.find MANUALS.rand}
  end

  x.report 'insert (without FriendlyId)' do
    N.times {transaction {Book.create :name => FFaker::Name.name}}
  end

  x.report 'insert (in-table-slug)' do
    N.times {transaction {Journalist.create :name => FFaker::Name.name}}
  end

  x.report 'insert (in-table-slug; using finders module)' do
    N.times {transaction {Restaurant.create :name => FFaker::Name.name}}
  end

  x.report 'insert (external slug)' do
    N.times {transaction {Manual.create :name => FFaker::Name.name}}
  end
end
