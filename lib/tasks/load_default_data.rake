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

desc 'Load Redmine default configuration data. Language is chosen interactively or by setting REDMINE_LANG environment variable.'

namespace :redmine do
  task load_default_data: :environment do
    include Redmine::I18n
    set_language_if_valid('en')

    envlang = ENV['REDMINE_LANG']
    if !envlang || !set_language_if_valid(envlang)
      puts
      loop do
        print 'Select language: '
        print valid_languages.collect(&:to_s).sort.join(', ')
        print " [#{current_language}] "
        STDOUT.flush
        lang = STDIN.gets.chomp!
        break if lang.empty?
        break if set_language_if_valid(lang)
        puts 'Unknown language!'
      end
      STDOUT.flush
      puts '===================================='
    end

    begin
      Redmine::DefaultData::Loader.load(current_language)
      puts 'Default configuration data loaded.'
    rescue Redmine::DefaultData::DataAlreadyLoaded => error
      puts error
    rescue => error
      puts 'Error: ' + error.message
      puts error.backtrace.join("\n")
      puts 'Default configuration data was not loaded.'
    end
  end
end
