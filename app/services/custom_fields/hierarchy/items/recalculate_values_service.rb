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

module CustomFields
  module Hierarchy
    module Items
      class RecalculateValuesService < ::BaseServices::BaseContracted
        def initialize(user:, model:, contract_class: AdminOnlyContract, contract_options: {})
          self.model = model
          super(user:, contract_class:, contract_options:)
        end

        protected

        def persist(service_result)
          recalculate_customized(params[:item_ids]) if model.field_format_weighted_item_list?

          service_result
        end

        private

        def recalculate_customized(item_ids)
          model.class.customized_class
               .where(custom_values: model.custom_values.where(value: item_ids))
               .find_each do |customized|
            affected_cfs = customized.available_custom_fields.affected_calculated_fields([model.id])

            customized.calculate_custom_fields(affected_cfs)
            # rubocop:disable-next Rails/SaveBang
            customized.save if customized.changed_for_autosave?
          end
        end
      end
    end
  end
end
