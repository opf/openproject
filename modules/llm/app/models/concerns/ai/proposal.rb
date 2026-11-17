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
  # A proposed change to a work package, in the vocabulary of Automations: a target and a
  # list of actions with values. Findings of a run and answers in the chat both carry one,
  # and AI::Assistance::ApplyProposalService applies either.
  #
  # Including classes implement:
  # - proposal_work_package, proposal_user
  # - proposal_changeable_attributes: the action keys allowed now
  # - proposal_journal_cause
  # - proposal_siblings: the other open proposals made from the same work package version
  module Proposal
    extend ActiveSupport::Concern

    # Only "self" is a target for now; parent, children and related come later.
    def self.change_set_for(actions)
      { "target" => "self", "actions" => actions.map { |key, values| { "key" => key.to_s, "values" => Array(values) } } }
    end

    included do
      enum :state, { open: "open", applied: "applied", dismissed: "dismissed" }, default: "open", validate: true

      validate :change_set_shape
    end

    def change_set?
      change_set.present?
    end

    def change_actions
      Array(change_set&.fetch("actions", nil))
    end

    def change_value_for(key)
      change_actions.find { |action| action["key"] == key.to_s }&.dig("values", 0)
    end

    def comment_only?
      change_actions.pluck("key") == %w[comment]
    end

    # Attachment references, mentions and macros that the proposed description would drop.
    def lost_references
      @lost_references ||= begin
        description = change_value_for(:description)
        description ? AI::Assistance::ContentGuard.lost_references(proposal_work_package.description, description) : []
      end
    end

    private

    def change_set_shape
      return if change_set.nil?

      errors.add(:change_set, :invalid) unless valid_change_set?
    end

    def valid_change_set?
      change_set.is_a?(Hash) && change_set["target"] == "self" && valid_change_actions?(change_set["actions"])
    end

    def valid_change_actions?(actions)
      actions.is_a?(Array) && actions.any? &&
        actions.all? { |a| a.is_a?(Hash) && a["key"].is_a?(String) && a["values"].is_a?(Array) }
    end
  end
end
