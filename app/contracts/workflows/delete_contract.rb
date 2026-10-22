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

module Workflows
  class DeleteContract < ::ModelContract
    include AuthorizesVariantAuthoring

    def self.model = Workflow

    validate :replacement_selected_when_in_use
    validate :replacement_is_available

    private

    def replacement_selected_when_in_use
      return unless model.in_use?

      errors.add(:base, :replacement_workflow_required) if options[:target].nil?
    end

    def replacement_is_available
      target = options[:target]
      return if target.nil?

      errors.add(:base, :replacement_workflow_invalid) if model.replacement_targets.exclude?(target)
    end
  end
end
