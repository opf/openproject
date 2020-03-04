#-- encoding: UTF-8

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

module WorkPackages
  module Bulk
    class UpdateService
      include ::Shared::ServiceContext
      include ::HookHelper

      attr_accessor :user, :work_packages, :permitted_params

      def initialize(user:, work_packages:)
        self.user = user
        self.work_packages = work_packages
      end

      def call(params:)
        self.permitted_params = PermittedParams.new(params, user)
        in_user_context do
          bulk_update(params)
        end
      end

      private

      def bulk_update(params)
        saved = []
        errors = {}

        work_packages.each do |work_package|
          work_package.add_journal(user, params[:notes])

          # filter parameters by whitelist and add defaults
          attributes = parse_params_for_bulk_work_package_attributes params, work_package.project

          call_hook(:controller_work_packages_bulk_edit_before_save, params: params, work_package: work_package)

          service_call = WorkPackages::UpdateService
                         .new(user: user, model: work_package)
                         .call(attributes.merge(send_notifications: params[:send_notification] == '1').symbolize_keys)

          if service_call.success?
            saved << work_package.id
          else
            errors[work_package.id] = service_call.errors.full_messages
          end
        end

        ServiceResult.new success: errors.empty?, result: saved, errors: errors
      end

      def parse_params_for_bulk_work_package_attributes(params, project)
        return {} unless params.has_key? :work_package

        safe_params = permitted_params.update_work_package project: project
        attributes = safe_params.reject { |_k, v| v.blank? }
        attributes.keys.each do |k|
          attributes[k] = '' if attributes[k] == 'none'
        end
        attributes[:custom_field_values].reject! { |_k, v| v.blank? } if attributes[:custom_field_values]
        attributes.delete :custom_field_values if not attributes.has_key?(:custom_field_values) or attributes[:custom_field_values].empty?
        attributes.to_h
      end
    end
  end
end
