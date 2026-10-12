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

module AI
  module Assistance
    # The proposed change of a finding or a chat answer: one diff or "old → new" for each
    # action, and the Apply button.
    class ProposalComponent < ApplicationComponent
      attr_reader :proposal, :apply_path

      def initialize(proposal:, apply_path:)
        super
        @proposal = proposal
        @apply_path = apply_path
      end

      def render?
        proposal.open? && proposal.change_set?
      end

      def work_package
        proposal.proposal_work_package
      end

      # Text fields as a diff; other fields as "old → new" with readable names.
      def changes
        proposal.change_actions.map do |action|
          key = action["key"]
          new_value = action["values"].first.to_s
          if AI::AssistantRuns::ChangeOptions::TEXT_KEYS.include?(key)
            { label: label(key), diff: diff(key, current_value(key), new_value) }
          else
            { label: label(key), from: current_label(key), to: new_label(key, new_value) }
          end
        end
      end

      def lost_references
        description = proposal.change_value_for(:description)
        return [] unless description

        AI::AssistantRuns::ContentGuard.lost_references(work_package.description, description)
      end

      def can_apply?
        lost_references.empty? && User.current.allowed_in_work_package?(:edit_work_packages, work_package)
      end

      private

      def label(key)
        I18n.t("ai_assistance.apply.label.#{key}", default: WorkPackage.human_attribute_name(key))
      end

      def current_value(key)
        work_package.respond_to?(key) ? work_package.public_send(key).to_s : ""
      end

      def current_label(key)
        value = work_package.public_send(key)
        if value.respond_to?(:name) then value.name
        elsif value.respond_to?(:iso8601) then helpers.format_date(value)
        else value.to_s
        end
      end

      def new_label(key, value)
        if AI::AssistantRuns::ChangeOptions::DATE_KEYS.include?(key)
          helpers.format_date(Date.iso8601(value))
        else
          change_options.label(key, value)
        end
      rescue Date::Error
        value
      end

      def change_options
        @change_options ||= AI::AssistantRuns::ChangeOptions.new(keys: proposal.proposal_changeable_attributes,
                                                           work_package:, user: proposal.proposal_user)
      end

      def diff(key, old_value, new_value)
        if key == "description"
          OpenProject::HtmlDiff.from_markdown(old_value, new_value)
        else
          Redmine::Helpers::Diff.new(new_value, old_value).to_html
        end
      end
    end
  end
end
