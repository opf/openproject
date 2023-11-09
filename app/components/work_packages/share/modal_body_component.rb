#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module Share
    class ModalBodyComponent < ApplicationComponent
      include ApplicationHelper
      include MemberHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include WorkPackages::Share::Concerns::Authorization
      include WorkPackages::Share::Concerns::DisplayableRoles

      def initialize(work_package:, shares:)
        super

        @work_package = work_package
        @shared_principals = shares
      end

      def self.wrapper_key
        "work_package_share_list"
      end

      private

      def insert_target_modified?
        true
      end

      def insert_target_modifier_id
        'op-share-wp-active-shares'
      end

      # There is currently no available system argument for setting an id on the
      # rendered <ul> tag that houses the row slots on Primer::Beta::BorderBox components.
      # Setting an id is required to be able to uniquely identify a target for
      # TurboStream +insert+ actions and being able to prepend and append to it.
      def invited_user_list(&)
        border_box = Primer::Beta::BorderBox.new

        set_id_on_list_element(border_box)

        render(border_box, &)
      end

      def set_id_on_list_element(list_container)
        new_list_arguments = list_container.instance_variable_get(:@list_arguments)
                                           .merge(id: insert_target_modifier_id)

        list_container.instance_variable_set(:@list_arguments, new_list_arguments)
      end

      def type_filter_options
        [
          { label: I18n.t('work_package.sharing.filter.project_member'),
            value: { principal_type: 'User', project_member: true } },
          { label: I18n.t('work_package.sharing.filter.not_project_member'),
            value: { principal_type: 'User', project_member: false } },
          { label: I18n.t('work_package.sharing.filter.project_group'),
            value: { principal_type: 'Group', project_member: true } },
          { label: I18n.t('work_package.sharing.filter.not_project_group'),
            value: { principal_type: 'Group', project_member: false } }
        ]
      end

      def type_filter_option_active?(_option)
        principal_type_filter_value = current_filter_value(params[:filters], 'principal_type')
        project_member_filter_value = current_filter_value(params[:filters], 'also_project_member')

        return false if principal_type_filter_value.nil? || project_member_filter_value.nil?

        principal_type_checked =
          _option[:value][:principal_type] == principal_type_filter_value
        membership_selected =
          _option[:value][:project_member] == ActiveRecord::Type::Boolean.new.cast(project_member_filter_value)

        principal_type_checked && membership_selected
      end

      def role_filter_option_active?(_option)
        role_filter_value = current_filter_value(params[:filters], 'role_id')

        return false if role_filter_value.nil?

        find_role_ids(_option[:value]).first == role_filter_value.to_i
      end

      def filter_url(type_option: nil, role_option: nil)
        args = {}
        filter = []

        unless type_option.nil? || type_filter_option_active?(type_option)
          if type_option[:value][:project_member]
            filter.push({ also_project_member: { operator: "=", values: [OpenProject::Database::DB_VALUE_TRUE] } })
          else
            filter.push({ also_project_member: { operator: "=", values: [OpenProject::Database::DB_VALUE_FALSE] } })
          end

          filter.push({ principal_type: { operator: "=", values: [type_option[:value][:principal_type]] } })
        end

        unless role_option.nil? || role_filter_option_active?(role_option)
          filter.push({ role_id: { operator: "=", values: find_role_ids(role_option[:value]) } })
        end

        # Todo: Keep options of the other filter defined in params

        args[:filters] = filter.to_json unless filter.empty?

        work_package_shares_path(args)
      end

      def current_filter_value(filters, filter_key)
        return nil if filters.nil?

        given_filters = JSON.parse(filters).find { |key| key.key?(filter_key) }
        given_filters ? given_filters[filter_key]['values'].first : nil
      end
    end
  end
end
