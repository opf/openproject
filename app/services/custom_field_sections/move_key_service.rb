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

module CustomFieldSections
  # The key's membership in the source section is re-checked under the lock,
  # since a concurrent move may have taken it away in the meantime.
  class MoveKeyService < ::BaseServices::BaseCallable
    def initialize(key:, from:, to:, custom_field: nil)
      super()
      @key = key
      @from = from
      @to = to.id == from.id ? from : to
      @custom_field = custom_field
    end

    def perform
      if move_under_lock(params[:prev_key])
        ServiceResult.success(result: {
                                section_changed: section_changed?,
                                current_section: @to.reload,
                                old_section: section_changed? ? @from.reload : nil
                              })
      else
        ServiceResult.failure(errors: I18n.t(:error_invalid_list_move_anchor))
      end
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages)
    end

    private

    def move_under_lock(prev_key)
      moved = false

      CustomFieldSection.transaction(requires_new: true) do
        [@from, @to].uniq.sort_by(&:id).each(&:lock!)
        moved = still_in_source? && move(prev_key)

        raise ActiveRecord::Rollback unless moved
      end

      moved
    end

    def still_in_source?
      if @custom_field
        @custom_field.reload.custom_field_section_id == @from.id
      else
        @from.attribute_order.include?(@key)
      end
    end

    def move(prev_key)
      if section_changed?
        @from.remove_from_order(@key)
        @custom_field&.update!(custom_field_section_id: @to.id)
      end

      @to.insert_after_key(@key, prev_key)
    end

    def section_changed?
      @from.id != @to.id
    end
  end
end
