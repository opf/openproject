#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module WorkPackages
      module Form
        class FormAPI < ::Cuba
          include API::Helpers
          include API::V3::Utilities::PathHelper
          include API::V3::WorkPackages::Helpers

          def process_form_request
            write_work_package_attributes
            write_request_valid?

            error = ::API::Errors::ErrorBase.create(@representer.represented.errors)

            if error.is_a? ::API::Errors::Validation
              res.status = 200
              res.write FormRepresenter.new(@representer.represented, current_user: current_user).to_json
            else
              fail error
            end
          end

          define do
            @work_package = env['work_package']
            @representer  = env['work_package_representer']

            on post, root do
              process_form_request
            end
          end
        end
      end
    end
  end
end
