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
    module Projects
      module Copy
        class ProjectCopyMetaRepresenter < ::API::Decorators::Single
          ::Projects::CopyService.copyable_dependencies.each do |dep|
            identifier = dep[:identifier]

            property :"copy_#{identifier}",
                     exec_context: :decorator,
                     getter: ->(*) do
                       only = represented&.only

                       only.nil? || only.include?(identifier)
                     end,
                     reader: ->(doc:, **) { doc.fetch("copy#{identifier.camelize}", true) },
                     setter: ->(fragment:, **) do
                       represented.only ||= Set.new
                       represented.only << identifier unless fragment == false
                     end
          end

          property :send_notifications,
                   exec_context: :decorator,
                   getter: ->(*) do
                     # Default to false
                     represented.send_notifications || false
                   end,
                   setter: ->(fragment:, **) do
                     represented.send_notifications = fragment
                   end

          def model_required?
            false
          end
        end
      end
    end
  end
end
