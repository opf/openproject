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
  module Utilities
    module Endpoints
      class Delete
        include NamespacedLookup

        def default_instance_generator(model)
          ->(_params) do
            instance_variable_get(:"@#{model.name.demodulize.underscore}")
          end
        end

        def initialize(model:,
                       instance_generator: nil,
                       process_service: nil,
                       success_status: 204,
                       api_name: nil)
          self.model = model
          self.instance_generator = instance_generator || default_instance_generator(model)
          self.process_service = process_service || deduce_process_service
          self.api_name = api_name || model.name.demodulize
          self.success_status = success_status
        end

        def mount
          delete = self

          -> do
            call = delete.process(self)

            delete.render(call) do
              status delete.success_status
            end
          end
        end

        def process(request)
          process_service
            .new(user: request.current_user,
                 model: request.instance_exec(request.params, &instance_generator))
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

        attr_accessor :model,
                      :instance_generator,
                      :process_service,
                      :api_name,
                      :success_status

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
          lookup_namespaced_class("DeleteService")
        end

        def deduce_api_namespace
          api_name.pluralize
        end
      end
    end
  end
end
