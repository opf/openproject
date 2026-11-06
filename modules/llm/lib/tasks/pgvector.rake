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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

pgvector_failure = nil

namespace :openproject do
  namespace :llm do
    namespace :pgvector do
      desc "Include the pgvector migrations in db:migrate if the extension can be installed on this database"
      task include_migrations_path_if_installable: :environment do
        pgvector_failure = OpenProject::Llm::Pgvector.include_migrations_path_if_installable!
      rescue ActiveRecord::NoDatabaseError
        # db:migrate creates the database after this task. The next run installs the extension via its migrations.
      end
    end
  end
end

Rake::Task["db:migrate"].enhance ["openproject:llm:pgvector:include_migrations_path_if_installable"] do
  warn OpenProject::Llm::Pgvector.warning(pgvector_failure) if pgvector_failure
end
