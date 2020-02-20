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
      class Bodied
        def default_instance_generator(_model)
          raise NotImplementedError
        end

        def default_params_modifier
          ->(params) do
            params
          end
        end

        def initialize(model:,
                       api_name: model.name.demodulize,
                       instance_generator: default_instance_generator(model),
                       params_modifier: default_params_modifier,
                       process_service: nil,
                       parse_service: nil)
          self.model = model
          self.api_name = api_name
          self.instance_generator = instance_generator
          self.params_modifier = params_modifier
          self.parse_representer = deduce_parse_representer
          self.render_representer = deduce_render_representer
          self.process_contract = deduce_process_contract
          self.process_service = process_service || deduce_process_service
          self.parse_service = parse_service || deduce_parse_service
        end

        def mount
          update = self

          -> do
            params = update.parse(current_user, request_body)

            params = instance_exec(params, &update.params_modifier)

            call = update.process(current_user,
                                  instance_exec(params, &update.instance_generator),
                                  params)

            update.render(current_user, call) do
              status update.success_status
            end
          end
        end

        def parse(current_user, request_body)
          parse_service
            .new(current_user,
                 model: model,
                 representer: parse_representer)
            .call(request_body)
            .result
        end

        def process(current_user, instance, params)
          args = { user: current_user,
                   model: instance,
                   contract_class: process_contract }

          process_service
            .new(args.compact)
            .call(params)
        end

        def render(current_user, call)
          if success?(call)
            yield
            present_success(current_user, call)
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
                      :params_modifier,
                      :process_contract,
                      :process_service,
                      :parse_service

        private

        def present_success(_current_user, _call)
          raise NotImplementedError
        end

        def present_error(_call)
          raise NotImplementedError
        end

        def success?(call)
          call.success?
        end

        def deduce_process_service
          "::#{deduce_backend_namespace}::SetAttributesService".constantize
        end

        def deduce_process_contract
          "::#{deduce_backend_namespace}::#{update_or_create}Contract".constantize
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

        def backend_name
          model.name.demodulize
        end

        def deduce_backend_namespace
          backend_name.pluralize
        end

        def update_or_create
          raise NotImplementedError
        end
      end
    end
  end
end
