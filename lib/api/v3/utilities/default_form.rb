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
    module Utilities
      class DefaultForm
        def default_instance_generator(model)
          raise NotImplementedError
        end

        def initialize(model:,
                       instance_generator: default_instance_generator(model),
                       process_service: nil,
                       parse_service: API::V3::ParseResourceParamsService)
          self.model = model
          self.instance_generator = instance_generator
          self.parse_representer = deduce_parse_representer
          self.render_representer = deduce_render_representer
          self.contract = deduce_contract
          self.process_service = process_service || deduce_service
          self.parse_service = parse_service
        end

        def mount
          create = self

          -> do
            params = create.parse(current_user, request_body)

            call = create.process(current_user,
                                  instance_exec(params, current_user, &create.instance_generator),
                                  params)

            create.with_error_message_on_validation_error(call) do |errors|
              status 200
              create.present_success(current_user, call.result, errors)
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
                   contract_class: contract }

          args[demodulized_name.underscore.to_sym] = instance

          process_service
            .new(args)
            .call(params)
        end

        def present_success(current_user, result, errors)
          render_representer.new(result,
                                 errors: errors,
                                 current_user: current_user)
        end

        def present_error(errors)
          fail ::API::Errors::MultipleErrors.create_if_many(errors)
        end

        def with_error_message_on_validation_error(call)
          errors = ::API::Errors::ErrorBase.create_errors(call.errors)

          if only_validation_errors(errors)
            yield(errors)
          else
            present_error(errors)
          end
        end

        def only_validation_errors(errors)
          errors.all? { |error| error.code == 422 }
        end

        attr_accessor :model,
                      :instance_generator,
                      :parse_representer,
                      :render_representer,
                      :contract,
                      :process_service,
                      :parse_service

        private

        def deduce_service
          "::#{deduce_namespace}::SetAttributesService".constantize
        end

        def deduce_contract
          "::#{deduce_namespace}::#{update_or_create}Contract".constantize
        end

        def deduce_parse_representer
          "::API::V3::#{deduce_namespace}::#{demodulized_name}PayloadRepresenter".constantize
        end

        def deduce_render_representer
          "::API::V3::#{deduce_namespace}::#{update_or_create}FormRepresenter".constantize
        end

        def deduce_namespace
          demodulized_name.pluralize
        end

        def demodulized_name
          model.name.demodulize
        end

        def update_or_create
          raise NotImplementedError
        end
      end
    end
  end
end
