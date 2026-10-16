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

pgvector_failure = nil

namespace :openproject do
  namespace :llm do
    namespace :pgvector do
      desc "Create the pgvector extension if possible, so its migrations run with db:migrate"
      task try_enable: :environment do
        pgvector_failure = OpenProject::Llm::Pgvector.enable
      rescue ActiveRecord::NoDatabaseError
        # db:migrate creates the database after this task. The next run creates the extension.
      end

      desc "Show whether pgvector is available"
      task status: :environment do
        pgvector = OpenProject::Llm::Pgvector
        puts "Extension available on server: #{pgvector.extension_available?}"
        puts "Extension installed:           #{pgvector.extension_installed?}"
        puts "Migrations applied:            #{pgvector.migrations_applied?}"
      end
    end
  end
end

Rake::Task["db:migrate"].enhance ["openproject:llm:pgvector:try_enable"] do
  warn OpenProject::Llm::Pgvector.warning(pgvector_failure) if pgvector_failure
end
