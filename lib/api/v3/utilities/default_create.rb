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
        class << self
          def call(model: nil, representer: nil)
            raise ::ArgumentError, 'One of model or representer needs to be provided' unless model || representer

            service = deduce_service(model, representer)
            representer ||= deduce_representer(model)

            -> do
              params = API::V3::ParseResourceParamsService
                       .new(current_user, model: model, representer: representer)
                       .call(request_body)
                       .result

              call = service
                     .new(user: current_user)
                     .call(params)

              if call.success?
                representer.create(call.result,
                                   current_user: current_user,
                                   embed_links: true)
              else
                fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
              end
            end
          end

          private

          def deduce_service(model, representer)
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
end
