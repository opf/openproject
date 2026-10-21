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
  class ReplacementSelectForm < ApplicationForm
    def initialize(candidates:, validation_message: nil)
      super()

      @candidates = candidates
      @validation_message = validation_message
    end

    form do |replacement_form|
      replacement_form.select_list(
        name: :target_id,
        label: I18n.t("workflows.delete.replace_label"),
        caption: I18n.t("workflows.delete.replace_caption"),
        include_blank: I18n.t("workflows.delete.replace_placeholder"),
        validation_message: @validation_message,
        data: { test_selector: "workflow-replacement-select" }
      ) do |list|
        @candidates.each do |candidate|
          list.option(value: candidate.id, label: candidate.name)
        end
      end
    end
  end
end
