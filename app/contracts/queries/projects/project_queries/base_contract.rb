# -- copyright
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

module Queries::Projects::ProjectQueries
  class BaseContract < ::ModelContract
    attribute :name
    attribute :selects
    attribute :filters
    attribute :orders

    def self.model
      ProjectQuery
    end

    validates :name,
              presence: true,
              length: { maximum: 255 }

    validate :name_select_included
    # When we only changed the name, we don't need to validate the selects
    validate :existing_selects, unless: :only_changed_name?
    validate :user_is_logged_in
    validate :allowed_to_modify_private_query
    validate :allowed_to_modify_public_query

    protected

    def user_is_logged_in
      unless user.logged?
        errors.add :base, :error_unauthorized
      end
    end

    def allowed_to_modify_private_query
      return if model.public?
      return if model.user == user
      return if user.allowed_in_project_query?(:edit_project_query, model)

      errors.add :base, :can_only_be_modified_by_owner
    end

    def allowed_to_modify_public_query
      return unless model.public?
      return if user.allowed_in_project_query?(:edit_project_query, model)
      return if user.allowed_globally?(:manage_public_project_queries)

      errors.add :base, :need_permission_to_modify_public_query
    end

    def name_select_included
      if model.selects.none? { |s| s.attribute == :name }
        errors.add :selects, :name_not_included
      end
    end

    def existing_selects
      model.selects.select { |s| s.is_a?(Queries::Selects::NotExistingSelect) }.each do |s|
        errors.add :selects, :nonexistent, column: s.attribute
      end
    end

    def only_changed_name?
      model.changed == ["name"]
    end
  end
end
