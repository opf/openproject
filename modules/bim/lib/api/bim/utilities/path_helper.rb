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

module API
  module Bim
    module Utilities
      module PathHelper
        include API::Utilities::UrlHelper

        # rubocop:disable Naming/ClassAndModuleCamelCase
        module BCF2_1Path
          module_function

          # rubocop:enable Naming/ClassAndModuleCamelCase
          extend API::Utilities::UrlHelper

          # Determining the root_path on every url we want to render is
          # expensive. As the root_path will not change within a
          # request, we can cache the first response on each request.
          def root_path
            RequestStore.store[:cached_root_path] ||= super
          end

          def root
            "#{root_path}api/bcf/2.1/"
          end

          def project(identifier)
            "#{root}projects/#{identifier}"
          end

          def topics(project_identifier)
            "#{project(project_identifier)}/topics"
          end

          def topic(project_identifier, uuid)
            "#{topics(project_identifier)}/#{uuid}"
          end

          def viewpoint(project_identifier, topic_uuid, viewpoint_topic)
            "#{topic(project_identifier, topic_uuid)}/viewpoints/#{viewpoint_topic}"
          end
        end

        def bcf_v2_1_paths
          BCF2_1Path
        end
      end
    end
  end
end
