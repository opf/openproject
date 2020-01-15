#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
      module Schema
        module FormConfigurations
          class AttributeRepresenter < ::API::Decorators::Single
            attr_accessor :project

            def initialize(model, current_user:, project:, embed_links: false)
              self.project = project

              super(model, current_user: current_user, embed_links: embed_links)
            end

            property :name,
                     exec_context: :decorator

            property :attributes,
                     exec_context: :decorator

            def _type
              "WorkPackageFormAttributeGroup"
            end

            def name
              represented.translated_key
            end

            def attributes
              represented.active_members(project).map do |attribute|
                convert_property(attribute)
              end
            end

            def convert_property(attribute)
              ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
            end
          end
        end
      end
    end
  end
end
