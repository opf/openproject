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
    module TestManagement
      class CiConnectionRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_ci_connection(represented.id), title: represented.name }
        end

        link :project do
          { href: api_v3_paths.project(represented.project_id) }
        end

        link :repository do
          href = represented.repository_url.to_s.strip
          next unless href.match?(%r{\Ahttps?://[^\s]+\z}i)

          { href: }
        end

        property :id
        property :name
        property :provider
        property :repository
        property :ingest_mode, as: :ingestMode
        property :target_run_name, as: :targetRunName, render_nil: true
        property :active
        property :token_set, as: :tokenSet, getter: ->(*) { token_set? }
        property :workflow, render_nil: true
        property :trigger_ref, as: :ref, getter: ->(*) { effective_trigger_ref }
        property :trigger_ready, as: :triggerReady, getter: ->(*) { trigger_ready? }
        date_time_property :created_at
        date_time_property :updated_at

        def _type
          "TestManagementCiConnection"
        end
      end
    end
  end
end
