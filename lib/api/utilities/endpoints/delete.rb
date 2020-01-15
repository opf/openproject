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
      class Delete
        def default_instance_generator(model)
          ->(_params) do
            instance_variable_get("@#{model.name.demodulize.underscore}")
          end
        end

        def initialize(model:,
                       instance_generator: default_instance_generator(model),
                       process_service: nil,
                       api_name: model.name.demodulize)
          self.model = model
          self.instance_generator = instance_generator
          self.process_service = process_service || deduce_process_service
          self.api_name = api_name
        end

        def mount
          delete = self

          -> do
            call = delete.process(current_user,
                                  instance_exec(params, &delete.instance_generator))

            delete.render(call) do
              status delete.success_status
            end
          end
        end

        def process(current_user, instance)
          process_service
            .new(user: current_user,
                 model: instance)
            .call
        end

        def render(call)
          if success?(call)
            yield
            present_success(call)
          else
            present_error(call)
          end
        end

        def success_status
          204
        end

        attr_accessor :model,
                      :instance_generator,
                      :process_service,
                      :api_name

        private

        def present_error(call)
          fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
        end

        def present_success(call)
          # Handle success cases by subclasses
        end

        def success?(call)
          call.success?
        end

        def deduce_process_service
          "::#{deduce_backend_namespace}::DeleteService".constantize
        end

        def deduce_backend_namespace
          demodulized_name.pluralize
        end

        def demodulized_name
          model.name.demodulize
        end

        def deduce_api_namespace
          api_name.pluralize
        end
      end
    end
  end
end
