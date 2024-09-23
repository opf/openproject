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

class EnableUnaccentExtension < ActiveRecord::Migration[7.1]
  def up
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA pg_catalog;")
  rescue StandardError => e
    raise unless e.message.include?("unaccent")

    raise <<~MESSAGE
      \e[33mWARNING:\e[0m Could not find or enable the `unaccent` extension for PostgreSQL.
      This is needed for filtering users with accents, please install the postgresql-contrib module
      for your PostgreSQL installation using the package manager of your operating system.

      Once this package is installed, please re-run this migration like so:

      - Packaged installation: openproject run bundle exec rake db:migrate:redo 20240311111957
      - Docker installation: docker exec -it "container_id" bundle exec rake db:migrate:redo 20240311111957
      - Docker-compose installation: docker-compose exec app bundle exec rake db:migrate:redo 20240311111957

      Read more about the contrib module at `https://www.postgresql.org/docs/current/contrib.html`.
    MESSAGE
  end

  def down
    ActiveRecord::Base.connection.execute("DROP EXTENSION IF EXISTS unaccent CASCADE;")
  end
end
