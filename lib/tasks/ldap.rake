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

desc 'Creates a dummy LDAP auth source for logging in any user using the password "dummy".'
namespace :ldap do
  task create_dummy: :environment do
    source_name = 'DerpLAP'
    otf_reg = ARGV.include?('onthefly_register')

    source = DummyAuthSource.create name: source_name, onthefly_register: otf_reg

    puts
    if source.valid?
      puts "Created dummy auth source called \"#{source_name}\""
      puts 'On-the-fly registration support: ' + otf_reg.to_s
      unless otf_reg
        puts "use `rake ldap:create_dummy[onthefly_register]` to enable on-the-fly registration"
      end
    else
      puts "Dummy auth source already exists. It's called \"#{source_name}\"."
    end

    puts
    puts 'Note: Dummy auth sources cannot be edited, so clicking on them'
    puts "      in the 'LDAP Authentication' view will result in an error. Bummer!"
  end

  task delete_dummies: :environment do
    DummyAuthSource.destroy_all

    puts
    puts 'Deleted all dummy auth sources. Users who used it are out of luck! :o'
  end
end
