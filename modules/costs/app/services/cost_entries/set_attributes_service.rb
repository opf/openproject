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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CostEntries
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_attributes(_attributes)
      parse_overridden_costs

      super
    end

    # Called by parent SetAttributes#set_attributes
    def set_default_attributes(*)
      model.spent_on ||= Time.zone.today
    end

    # Called by parent SetAttributes#set_attributes for new records
    def ensure_default_attributes(*)
      set_project
      set_logged_by
    end

    def set_project
      model.project ||= model.entity&.project
    end

    # Always record the acting user as the one who logged the entry.
    def set_logged_by
      model.change_by_system do
        model.logged_by = user
      end
    end

    # The locale-aware units setter on the model already parses unit strings.
    # The overridden_costs column has no such setter, so we parse it here.
    def parse_overridden_costs
      return if params[:overridden_costs].blank?

      params[:overridden_costs] = CostRate.parse_number_string_to_number(params[:overridden_costs])
    end
  end
end
