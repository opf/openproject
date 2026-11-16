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
    class DeleteDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      def initialize(tree:)
        super()
        @tree = tree
      end

      private

      attr_reader :tree

      def form_arguments
        {
          action: ldap_departments_synchronized_tree_path(tree_id: tree.id),
          method: :delete
        }
      end

      def title
        I18n.t("ldap_departments.synchronized_trees.destroy.title", name: tree.name)
      end

      def heading
        I18n.t("ldap_departments.synchronized_trees.destroy.heading", name: tree.name)
      end

      def confirmation_text
        I18n.t("ldap_departments.synchronized_trees.destroy.confirmation_message",
               name: tree.name,
               count: tree.synchronized_departments.size)
      end

      def info_text
        I18n.t("ldap_departments.synchronized_trees.destroy.info")
      end
    end
  end
end
