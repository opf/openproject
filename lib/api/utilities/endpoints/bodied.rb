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
      class Bodied
        include NamespacedLookup

        def default_instance_generator(_model)
          raise NotImplementedError
        end

        def default_params_modifier
          ->(params) do
            params
          end
        end

        def default_process_state
          ->(**) do
            {}
          end
        end

        def default_params_source
          ->(request) do
            request.request_body
          end
        end

        def initialize(model:,
                       api_name: nil,
                       instance_generator: nil,
                       params_modifier: nil,
                       params_source: nil,
                       process_state: nil,
                       before_hook: nil,
                       parse_representer: nil,
                       render_representer: nil,
                       process_service: nil,
                       process_contract: nil,
                       parse_service: nil)
          self.model = model
          self.api_name = api_name || model.name.demodulize
          self.instance_generator = instance_generator || default_instance_generator(model)
          self.params_modifier = params_modifier || default_params_modifier
          self.params_source = params_source || default_params_source
          self.process_state = process_state || default_process_state
          self.parse_representer = parse_representer || deduce_parse_representer
          self.render_representer = render_representer || deduce_render_representer
          self.process_contract = process_contract || deduce_process_contract
          self.process_service = process_service || deduce_process_service
          self.parse_service = parse_service || deduce_parse_service
          self.before_hook = before_hook
        end

        def mount
          endpoint = self

          -> do
            request = self # proc is executed in the context of the grape request
            endpoint.before_hook&.(request:)
            params = endpoint.parse(request)
            call = endpoint.process(request, params)

            endpoint.render(request, call) do
              status endpoint.success_status
            end
          end
        end

        def parse(request)
          parse_service
            .new(request.current_user,
                 model:,
                 representer: parse_representer)
            .call(params_source.call(request))
            .result
        end

        def process(request, params)
          instance = request.instance_exec(params, &instance_generator)

          args = { user: request.current_user,
                   model: instance,
                   contract_class: process_contract }

          process_service
            .new(**args.compact)
            .with_state(request.instance_exec(model: instance, params:, &process_state))
            .call(**request.instance_exec(params, &params_modifier))
        end

        def render(request, call)
          if success?(call)
            yield
            present_success(request, call)
          else
            present_error(call)
          end
        end

        def success_status
          :ok
        end

        attr_accessor :model,
                      :api_name,
                      :instance_generator,
                      :parse_representer,
                      :render_representer,
                      :params_source,
                      :params_modifier,
                      :process_contract,
                      :process_service,
                      :parse_service,
                      :process_state,
                      :before_hook

        private

        def present_success(_request, _call)
          raise NotImplementedError
        end

        def present_error(_call)
          raise NotImplementedError
        end

        def success?(call)
          call.success?
        end

        def deduce_process_service
          lookup_namespaced_class("SetAttributesService")
        end

        def deduce_process_contract
          lookup_namespaced_class("#{update_or_create}Contract")
        end

        def deduce_parse_representer
          raise NotImplementedError
        end

        def deduce_parse_service
          raise NotImplementedError
        end

        def deduce_render_representer
          raise NotImplementedError
        end

        def deduce_api_namespace
          api_name.pluralize
        end

        def update_or_create
          raise NotImplementedError
        end
      end
    end
  end
end
