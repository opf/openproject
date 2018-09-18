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

require 'work_packages/base_contract'
require 'api/v3/work_packages/work_package_payload_representer'

module API
  module V3
    module WorkPackages
      module WorkPackagesSharedHelpers
        extend Grape::API::Helpers

        def work_package_representer(work_package = @work_package)
          ::API::V3::WorkPackages::WorkPackageRepresenter.create(
            work_package,
            current_user: current_user,
            embed_links: true
          )
        end

        def handle_work_package_errors(work_package, result)
          errors = result.errors
          errors = merge_dependent_errors work_package, result if errors.empty?

          api_errors = [::API::Errors::ErrorBase.create_and_merge_errors(errors)]

          fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
        end

        private

        def merge_dependent_errors(work_package, result)
          errors = ActiveModel::Errors.new work_package

          result.dependent_results.each do |dr|
            dr.errors.keys.each do |field|
              dr.errors.symbols_and_messages_for(field).each do |symbol, full_message, _|
                dependent_error = I18n.t(
                  :error_dependent_work_package,
                  related_id: dr.result.id,
                  related_subject: dr.result.subject,
                  error: full_message
                )

                errors.add :base, symbol, message: dependent_error
              end
            end
          end

          errors
        end

        def notify_according_to_params
          params[:notify] != 'false'
        end
      end
    end
  end
end
