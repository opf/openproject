#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Views
  class BaseContract < ::ModelContract
    attribute :query

    validate :type_allowed
    validate :query_present,
             :query_manageable

    def valid?(*_args)
      super

      # Registered views can have an additional contract configured that
      # needs to validate additionally. E.g. a contract can have additional permission checks.
      if (strategy_class = Constants::Views.contract_strategy(model.type))
        strategy = strategy_class.new(model, user)

        with_merged_former_errors do
          strategy.valid?
        end
      end

      errors.empty?
    end

    private

    def type_allowed
      unless Constants::Views.registered?(model.type)
        errors.add(:type, :inclusion)
      end
    end

    def query_present
      if model.query.blank?
        errors.add(:query, :blank)
      end
    end

    def query_manageable
      return if model.query.blank?

      if query_visible?
        errors.add(:base, :error_unauthorized) unless query_permissions?
      else
        errors.add(:query, :does_not_exist)
      end
    end

    def query_visible?
      Query.visible(user).exists?(id: model.query.id)
    end

    def query_permissions?
      # The visibility i.e. whether a private query belongs to the user is checked via the
      # query_visible? method.
      (model.query.public && user_allowed_on_query?(:manage_public_queries)) ||
        (!model.query.public && user_allowed_on_query?(:save_queries))
    end

    def user_allowed_on_query?(permission)
      if model.query.project
        user.allowed_in_project?(permission, model.query.project)
      else
        user.allowed_in_any_project?(permission)
      end
    end
  end
end
