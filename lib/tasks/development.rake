# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

namespace "development" do
  namespace "db" do
    desc <<~DESC
      Anonymize the currently connected database.
    DESC
    task anonymize: %w[environment] do
      db_name = ActiveRecord::Base.connection_db_config.configuration_hash[:database]

      puts
      puts "Anonymizing data in currently connected database (#{db_name}) is a destructive operation."
      puts

      exit 1 unless Readline.readline("You sure about this? y/N ").downcase.strip == "y"

      puts
      puts "Executing anonymize.sql ..."

      ActiveRecord::Base.connection.execute Rails.root.join("script/anonymize.sql").read

      puts
      puts "Anonymization finished."
    end

    desc <<~DESC
      Isolate the currently connected database.
      Removes everything because of which an OpenProject running on this database could communicate
      with the outside world. Most notably:
        * storages
        * web hooks
        * deploy targets
        * SMTP settings
        * users' email addresses
    DESC
    task isolate: %w[environment] do
      db_name = ActiveRecord::Base.connection_db_config.configuration_hash[:database]

      puts
      puts "Isolating data in currently connected database (#{db_name}) is a destructive operation."
      puts

      exit 1 unless Readline.readline("You sure about this? y/N ").downcase.strip == "y"

      puts
      puts "Executing isolate.sql ..."

      ActiveRecord::Base.connection.execute Rails.root.join("script/isolate.sql").read

      puts
      puts "Isolation finished."
    end
  end
end
