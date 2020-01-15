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
  module Utilities
    module Endpoints
      class Index
        include ::API::Utilities::PageSizeHelper

        def initialize(model:,
                       api_name: model.name.demodulize,
                       scope: nil,
                       render_representer: nil)
          self.model = model_class(model)
          self.scope = scope
          self.api_name = api_name
          self.render_representer = render_representer || deduce_render_representer
        end

        def mount
          raise NotImplementedError
        end

        attr_accessor :model,
                      :api_name,
                      :scope,
                      :render_representer

        private

        def deduce_render_representer
          raise NotImplementedError
        end

        def deduce_api_namespace
          api_name.pluralize
        end

        def model_class(scope)
          if scope.is_a? Class
            scope
          else
            scope.model
          end
        end
      end
    end
  end
end
