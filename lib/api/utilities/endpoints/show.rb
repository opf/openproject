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
      class Show
        def default_instance_generator(model)
          ->(_params) do
            instance_variable_get("@#{model.name.demodulize.underscore}")
          end
        end

        def initialize(model:,
                       api_name: model.name.demodulize,
                       render_representer: nil,
                       instance_generator: default_instance_generator(model))

          self.model = model
          self.api_name = api_name
          self.instance_generator = instance_generator
          self.render_representer = render_representer || deduce_render_representer
        end

        def mount
          show = self

          -> do
            show.render(instance_exec(params, &show.instance_generator))
          end
        end

        def render(instance)
          render_representer
            .create(instance,
                    current_user: User.current,
                    embed_links: true)
        end

        def self_path
          api_name.underscore.pluralize
        end

        attr_accessor :model,
                      :api_name,
                      :instance_generator,
                      :render_representer

        private

        def deduce_render_representer
          raise NotImplementedError
        end

        def deduce_api_namespace
          api_name.pluralize
        end
      end
    end
  end
end
