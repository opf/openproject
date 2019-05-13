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
      class DefaultCreate
        def initialize(model: nil, representer: nil)
          raise ::ArgumentError, 'One of model or representer needs to be provided' unless model || representer

          self.model = model
          self.representer = representer || deduce_representer(model)
        end

        def mount
          create = self

          -> do
            params = create.parse(current_user, request_body)

            call = create.process(current_user, params)

            if call.success?
              create.present_success(current_user, call.result)
            else
              create.present_error(call.errors)
            end
          end
        end

        def parse(current_user, request_body)
          API::V3::ParseResourceParamsService
            .new(current_user, model: model, representer: representer)
            .call(request_body)
            .result
        end

        def process(current_user, params)
          service
            .new(user: current_user)
            .call(params)
        end

        def present_success(current_user, result)
          representer.create(result,
                             current_user: current_user,
                             embed_links: true)
        end

        def present_error(errors)
          fail ::API::Errors::ErrorBase.create_and_merge_errors(errors)
        end

        private

        attr_accessor :model,
                      :representer


        def service
          @service ||= deduce_service
        end

        def deduce_service
          namespace = if model
                        model.name
                      else
                        representer.name.gsub('Representer', '')
                      end.demodulize.pluralize

          "::#{namespace}::CreateService".constantize
        end

        def deduce_representer(model)
          "::API::V3::#{model.name.pluralize}::#{model.name}Representer".constantize
        end
      end
    end
  end
end
