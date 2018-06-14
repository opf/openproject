#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module WorkPackages
      class WorkPackagePayloadRepresenter < WorkPackageRepresenter
        include ::API::Utilities::PayloadRepresenter

        cached_representer disabled: true

        def writeable_attributes
          super + %w[date attachments]
        end

        property :attachments,
                 exec_context: :decorator,
                 getter: ->(*) {},
                 setter: ->(fragment:, **) do
                   ids = fragment.map do |link|
                     ::API::Utilities::ResourceLinkParser.parse_id link['href'],
                                                                   property: :attachment,
                                                                   expected_version: '3',
                                                                   expected_namespace: :attachments
                   end

                   represented.attachment_ids = ids
                 end,
                 skip_render: ->(*) { true },
                 linked_resource: true,
                 uncacheable: true

        links :attachments do
          represented.attachments.map do |attachment|
            { href: api_v3_paths.attachment(attachment.id) }
          end
        end

        def load_complete_model(model)
          model
        end
      end
    end
  end
end
