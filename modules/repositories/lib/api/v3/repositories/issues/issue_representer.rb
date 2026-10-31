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

module API
  module V3
    module Repositories
      module Issues
        class IssueRepresenter < ::API::Decorators::Single
          include ::API::Decorators::DateProperty
          include ::API::Decorators::FormattableProperty
          include ::API::V3::Repositories::AuthorProperty

          self_link path: :repository_issue,
                    title_getter: ->(*) { represented.title }

          property :id
          property :display_id
          property :title
          formattable_property :description
          property :state
          property :labels,
                   exec_context: :decorator,
                   getter: ->(*) { represented.labels.map { it.slice("title", "color") } }
          property :project_name
          property :web_url
          author_property

          date_time_property :external_updated_at
          date_time_property :created_at
          date_time_property :updated_at

          self.to_preload = %i[repository_user]

          def _type
            "RepositoryIssue"
          end
        end
      end
    end
  end
end
