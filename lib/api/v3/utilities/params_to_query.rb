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
    module Utilities
      class ParamsToQuery
        class << self
          def collection_response(scope, current_user, params, representer: nil, self_link: nil)
            model = model_class(scope)

            query = ParamsToQueryService
                    .new(model, current_user)
                    .call(params)

            if query.valid?
              send_collection_response(model,
                                       merge_scopes(scope, query.results),
                                       current_user,
                                       params,
                                       representer,
                                       self_link)
            else
              raise ::API::Errors::InvalidQuery.new(query.errors.full_messages)
            end
          end

          private

          def send_collection_response(model, scope, current_user, params, provided_representer, self_link_base)
            model_name = model.name
            model_name_plural = model_name.pluralize

            representer = provided_representer ||
                          "::API::V3::#{model_name_plural}::#{model_name}CollectionRepresenter"
                          .constantize

            link = if self_link_base
                     append_params_to_link(self_link_base, params)
                   else
                     default_self_link(model_name_plural.downcase, params)
                   end

            representer.new(scope,
                            link,
                            current_user: current_user)
          end

          def paths
            PathHelper::ApiV3Path
          end

          def default_self_link(path, params)
            [paths.send(path), params.to_query].reject(&:empty?).join('?')
          end

          def append_params_to_link(path, params)
            [path, params.to_query].reject(&:empty?).join('?')
          end

          def model_class(scope)
            if scope.is_a? Class
              scope
            else
              scope.model
            end
          end

          def merge_scopes(scope_a, scope_b)
            if scope_a.is_a? Class
              scope_b
            else
              scope_a.merge(scope_b)
            end
          end
        end
      end
    end
  end
end
