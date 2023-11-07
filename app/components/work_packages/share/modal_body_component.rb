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

      def role_filter_option_active?(option)
        return false if params[:filters].nil?

        given_role_filters = JSON.parse(params[:filters]).find { |filter| filter.key?('role_id') }
        given_role_filter_value = given_role_filters ? given_role_filters['role_id']['values'].first.to_i : nil

        find_role_ids(option[:value]).first == given_role_filter_value unless given_role_filter_value.nil?
      end

      def filter_url(role_option:)
        args = {}
        filter = []

        unless role_filter_option_active?(role_option)
          filter.push({ role_id: { operator: "=", values: find_role_ids(role_option[:value]) } })
        end

        args[:filters] = filter.to_json unless filter.empty?

        work_package_shares_path(args)
      end
    end
  end
end
