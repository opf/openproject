# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
      Queries::Projects::ProjectQuery
    end

    validates :name,
              presence: true,
              length: { maximum: 255 }

    validate :user_is_current_user_and_logged_in
    validate :name_select_included
    validate :existing_selects


    def user_is_current_user_and_logged_in
      unless user.logged? && user == model.user
        errors.add :base, :error_unauthorized
      end
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
  end
end
