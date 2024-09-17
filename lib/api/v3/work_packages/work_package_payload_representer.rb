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
  module V3
    module WorkPackages
      class WorkPackagePayloadRepresenter < WorkPackageRepresenter
        include ::API::Utilities::PayloadRepresenter
        include ::API::V3::Attachments::AttachablePayloadRepresenterMixin

        cached_representer disabled: true

        property :file_links,
                 exec_context: :decorator,
                 getter: ->(*) {},
                 setter: ->(fragment:, **) do
                   next unless fragment.is_a?(Array)

                   ids = fragment.map do |link|
                     ::API::Utilities::ResourceLinkParser.parse_id link["href"],
                                                                   property: :file_link,
                                                                   expected_version: "3",
                                                                   expected_namespace: :file_links
                   end

                   represented.file_links_ids = ids
                 end,
                 skip_render: ->(*) { true },
                 linked_resource: true,
                 uncacheable: true

        def writable_attributes
          super + %w[date]
        end

        def load_complete_model(model)
          model
        end
      end
    end
  end
end
