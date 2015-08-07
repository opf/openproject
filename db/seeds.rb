#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# This file should contain all the record creation needed to seed the database
# with its default values.  The data can then be loaded with the rake db:seed
# (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
#
# loads environment-specific seeds. The assumed directory structure in db/ is like this:
# |___seeds
# | |___all.rb
# | |___development.rb
# | |___staging.rb
# | |___production.rb
# |___seeds.rb

# clear some schema caches and column information.
ActiveRecord::Base.descendants.each do |klass|
  klass.connection.schema_cache.clear!
  klass.reset_column_information
end

# willfully ignoring Redmine::I18n and it's
# #set_language_if_valid here as it
# would mean to circumvent the default settings
# for valid_languages.
include Redmine::I18n
desired_lang = (ENV['LOCALE'] || :en).to_sym

if all_languages.include?(desired_lang)
  I18n.locale = desired_lang
  puts "*** Seeding for locale: '#{I18n.locale}'"
else
  raise "Locale #{desired_lang} is not supported"
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
