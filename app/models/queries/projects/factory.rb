# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

class Queries::Projects::Factory
  class << self
    def find(id)
      static_query(id) || Queries::Projects::ProjectQuery.find(id)
    end

    def static_query(id)
      case id
      when 'all'
        static_query_all
      when 'my'
        static_query_my
      when 'archived'
        static_query_archived
      end
    end

    def static_query_all
      Queries::Projects::ProjectQuery.new(name: I18n.t(:'projects.lists.all')) do |query|
        query.where('active', '=', OpenProject::Database::DB_VALUE_TRUE)

        query.order(lft: :asc)
      end
    end

    def static_query_my
      Queries::Projects::ProjectQuery.new(name: I18n.t(:'projects.lists.my')) do |query|
        query.where('member_of', '=', OpenProject::Database::DB_VALUE_TRUE)

        query.order(lft: :asc)
      end
    end

    def static_query_archived
      Queries::Projects::ProjectQuery.new(name: I18n.t(:'projects.lists.archived')) do |query|
        query.where('active', '=', OpenProject::Database::DB_VALUE_FALSE)

        query.order(lft: :asc)
      end
    end
  end
end
