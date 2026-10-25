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
    # Applies a proposal (a finding of a run, or an answer in the chat) through the
    # Automations services, as the user it was made for. It only applies to the work
    # package as it was when the proposal was made: any change since then is a conflict.
    class ApplyProposalService
      attr_reader :proposal, :user

      def initialize(proposal:, user:)
        @proposal = proposal
        @user = user
      end

      def call
        error = precondition_error
        return failure(error) if error

        work_package = proposal.proposal_work_package.reload
        # A comment alone conflicts with nothing, so it skips the version check.
        work_package.lock_version = proposal.base_lock_version unless proposal.comment_only?
        work_package.journal_cause = proposal.proposal_journal_cause

        result = Automations::UpdateWorkPackageService
                   .new(action: Automation.new(name: "AI Assistance", actions:), user:, strict: true)
                   .call(work_package:)

        if result.success?
          applied(work_package)
        else
          failure(conflict?(result) ? :conflict : :invalid, result.errors)
        end
      end

      private

      def precondition_error
        if proposal.proposal_user != user || !allowed_change_set? then :not_allowed
        elsif !proposal.open? || !proposal.change_set? then :not_open
        elsif proposal.lost_references.any? then :lost_content
        end
      end

      # Only actions and values that are allowed now: an admin may have narrowed the
      # skill's proposal scope since. The target is always "self" (AI::Proposal validates it).
      def allowed_change_set?
        options = ChangeOptions.new(keys: proposal.proposal_changeable_attributes,
                                    work_package: proposal.proposal_work_package, user:)
        proposal.change_actions.all? { |action| options.allowed?(action["key"], action["values"].first) }
      end

      def actions
        templates = Automations::Register.actions.flat_map(&:templates).index_by(&:key)
        proposal.change_actions.map do |change_action|
          action = templates.fetch(change_action["key"].to_sym).dup
          action.values = change_action["values"]
          action
        end
      end

      # The change is ours, so the other open proposals made from the same version stay
      # applicable.
      def applied(work_package)
        proposal.class.transaction do
          proposal.proposal_siblings.where(base_lock_version: proposal.base_lock_version)
                  .update_all(base_lock_version: work_package.lock_version)
          proposal.update!(state: "applied", base_lock_version: work_package.lock_version)
        end
        ServiceResult.success(result: work_package)
      end

      def conflict?(result)
        result.errors&.symbols_for(:base)&.include?(:error_conflict)
      end

      def failure(reason, errors = nil)
        message = I18n.t("ai_assistance.apply.errors.#{reason}")
        message = [message, errors.full_messages.to_sentence].compact_blank.join(" ") if reason == :invalid && errors
        ServiceResult.failure(message:, result: reason)
      end
    end
  end
end
