#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
#
# loads environment-specific seeds. The assumed directory structure in db/ is like this:
#|___seeds
#| |___all.rb
#| |___development.rb
#| |___staging.rb
#| |___production.rb
#|___seeds.rb

# clear some schema caches and column information.
ActiveRecord::Base.descendants.each do |klass|
  klass.connection.schema_cache.clear!
  klass.reset_column_information
end

['all', Rails.env].each do |seed|
  seed_file = "#{Rails.root}/db/seeds/#{seed}.rb"
  if File.exists?(seed_file)
    puts "*** Loading #{seed} seed data"
    require seed_file
  end
end

Rails::Application::Railties.engines.each do |engine|
  puts "*** Loading #{engine.engine_name} seed data"
  engine.load_seed
end
