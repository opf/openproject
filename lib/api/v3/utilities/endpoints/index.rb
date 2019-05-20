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
      module Endpoints
        class Index
          include ::API::Utilities::PageSizeHelper

          def initialize(model:)
            self.model = model
            self.render_representer = deduce_render_representer
          end

          def mount
            index = self

            -> do
              query = index.parse(params)

              self_path = api_v3_paths.send(index.self_path)

              index.render(query, params, self_path)
            end
          end

          def parse(params)
            ParamsToQueryService
              .new(model, User.current)
              .call(params)
          end

          def render(query, params, self_path)
            if query.valid?
              render_success(query, params, self_path)
            else
              render_error(query)
            end
          end

          def self_path
            demodulized_name.underscore.pluralize
          end

          attr_accessor :model,
                        :render_representer

          private

          def render_success(query, params, self_path)
            render_representer
              .new(query.results,
                   self_path,
                   page: to_i_or_nil(params[:offset]),
                   per_page: resolve_page_size(params[:pageSize]),
                   current_user: User.current)
          end

          def render_error(query)
            raise ::API::Errors::InvalidQuery.new(query.errors.full_messages)
          end

          def deduce_render_representer
            "::API::V3::#{deduce_namespace}::#{demodulized_name}CollectionRepresenter".constantize
          end

          def deduce_namespace
            demodulized_name.pluralize
          end

          def demodulized_name
            model.name.demodulize
          end
        end
      end
    end
  end
end
