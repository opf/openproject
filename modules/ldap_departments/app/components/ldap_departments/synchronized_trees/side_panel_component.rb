# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LdapDepartments
  module SynchronizedTrees
    class SidePanelComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(tree:)
        super()
        @tree = tree
      end

      private

      attr_reader :tree

      # [label, value] pairs shown in the side panel; optional attributes are only listed when set.
      def attributes
        shown_keys.map { |key| [SynchronizedTree.human_attribute_name(key), value_for(key)] }
      end

      def shown_keys
        keys = %i[ldap_auth_source base_dn structure_filter_string ou_name_attribute]
        keys << :guid_attribute if tree.guid_attribute.present?
        keys << :user_filter_string if tree.user_filter_string.present?
        keys << :sync_users
        keys
      end

      def value_for(key)
        case key
        when :ldap_auth_source then tree.ldap_auth_source&.name
        when :sync_users then checkmark_text(tree.sync_users)
        else tree.public_send(key)
        end
      end

      def checkmark_text(value)
        value ? I18n.t(:general_text_Yes) : I18n.t(:general_text_No)
      end
    end
  end
end
