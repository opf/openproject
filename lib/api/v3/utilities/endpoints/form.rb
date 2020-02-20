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
      module Endpoints
        class Form < API::Utilities::Endpoints::Bodied
          include V3Deductions

          def success?(call)
            only_validation_errors?(api_errors(call))
          end

          def present_success(current_user, call)
            render_representer
              .new(call.result,
                   errors: api_errors(call),
                   current_user: current_user)
          end

          def present_error(call)
            fail ::API::Errors::MultipleErrors.create_if_many(api_errors(call))
          end

          def only_validation_errors?(errors)
            errors.all? { |error| error.code == 422 }
          end

          private

          def api_errors(call)
            ::API::Errors::ErrorBase.create_errors(call.errors)
          end

          def deduce_render_representer
            "::API::V3::#{deduce_api_namespace}::#{update_or_create}FormRepresenter".constantize
          end
        end
      end
    end
  end
end
