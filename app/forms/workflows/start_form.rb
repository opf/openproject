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

module Workflows
  class StartForm < ApplicationForm
    COPY = "copy"
    SCRATCH = "scratch"

    def initialize(candidates:)
      super()

      @candidates = candidates
    end

    form do |start_form|
      start_form.radio_button_group(name: :start,
                                    label: I18n.t("workflows.start.label"),
                                    visually_hide_label: true,
                                    data: group_data) do |group|
        if candidates.any?
          group.radio_button(
            value: COPY,
            checked: true,
            label: I18n.t("workflows.start.copy.label"),
            caption: I18n.t("workflows.start.copy.caption"),
            data: {
              "workflows--start-choice-target": "copyRadio",
              test_selector: "workflow-start-copy"
            }
          ) do |radio|
            radio.nested_form(
              classes: "mt-2",
              data: { "workflows--start-choice-target": "copySource" }
            ) do |builder|
              CopySourceForm.new(builder, candidates:, selected: candidates.first.id)
            end
          end
        end

        group.radio_button(
          value: SCRATCH,
          checked: candidates.empty?,
          label: I18n.t("workflows.start.scratch.label"),
          caption: I18n.t("workflows.start.scratch.caption"),
          data: { test_selector: "workflow-start-scratch" }
        )
      end
    end

    private

    attr_reader :candidates

    def group_data
      {
        controller: "workflows--start-choice",
        action: "change->workflows--start-choice#toggle"
      }
    end
  end
end
