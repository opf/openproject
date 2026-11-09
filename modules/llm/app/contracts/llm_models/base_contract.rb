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
module LlmModels
  class BaseContract < ::ModelContract
    include RequiresAdminGuard
    include EnvNamedDefault

    attribute :display_name
    attribute :external_id, writable: -> { model.new_record? || model.manual? }
    attribute :raw_metadata, writable: -> { only_admin_context_window_changed? }

    validate :capability_states_known

    private

    def only_admin_context_window_changed?
      before, after = model.raw_metadata_change&.map { (it || {}).except("admin_context_window") }

      before == after
    end

    def capability_states_known
      model.capability_overrides.each do |capability, state|
        next if state.nil? || LlmCapabilityVerdict.states.key?(state)

        errors.add :"capability_#{capability}", :inclusion
      end
    end
  end
end
