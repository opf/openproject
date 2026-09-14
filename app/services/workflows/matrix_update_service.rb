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
  # Rewrites one tab of a variant's transition matrix for every selected role, delegating
  # the per-role write to BulkUpdateService so that either all roles are updated or none.
  #
  # Accepts the matrix straight from the submitted form, so that every context showing
  # the matrix — the workflow tab, the type creation wizard — persists it identically.
  class MatrixUpdateService
    def initialize(variant:, roles:, tab:)
      @variant = variant
      @roles = roles
      @tab = tab
    end

    # A linked variant reuses its source's transitions and must never have its own rewritten.
    def call(status: nil, indeterminate_status: nil)
      return ServiceResult.success if variant.linked?(TypeVariant::WORKFLOWS)

      persist(transitions: matrix(status), indeterminate: matrix(indeterminate_status))
    end

    private

    attr_reader :variant, :roles, :tab

    def persist(transitions:, indeterminate:)
      results = []

      Workflow.transaction do
        results = roles.map { update_role(it, transitions, indeterminate) }
        raise ActiveRecord::Rollback unless results.all?(&:success?)
      end

      results.find(&:failure?) || ServiceResult.success
    end

    def update_role(role, transitions, indeterminate)
      role_transitions = if indeterminate.empty?
                           transitions
                         else
                           restore_indeterminate(transitions, indeterminate, role)
                         end

      BulkUpdateService.new(role:, variant:, tab:).call(role_transitions)
    end

    # With several roles selected, a transition only some of them share renders as an
    # indeterminate checkbox, which submits as unchecked. Writing that back would drop the
    # transition for the roles that had it, so those pairs are restored from the database.
    def restore_indeterminate(transitions, indeterminate, role)
      transitions.deep_dup.tap do |restored|
        indeterminate.each do |old_status_id, new_status_ids|
          new_status_ids.each_key do |new_status_id|
            next unless transition_exists?(role, old_status_id, new_status_id)

            restored[old_status_id] ||= {}
            restored[old_status_id][new_status_id] = "1"
          end
        end
      end
    end

    def transition_exists?(role, old_status_id, new_status_id)
      saved_transitions.include?([role.id, old_status_id.to_i, new_status_id.to_i])
    end

    # Every indeterminate cell of every selected role is looked up against this, so it is
    # read once up front rather than per cell. Safe to reuse across roles even as they are
    # written: a role's write only ever touches its own rows.
    def saved_transitions
      @saved_transitions ||= Workflow
                               .where(type_variant_id: variant.id, role_id: roles.map(&:id), author: author?, assignee: assignee?)
                               .pluck(:role_id, :old_status_id, :new_status_id)
                               .to_set
    end

    # The matrix names its checkboxes status[old_status_id][new_status_id], so anything
    # that is not nested under a pair of numeric keys did not come from the rendered form.
    def matrix(source)
      return {} if source.blank?

      to_hash(source).select do |old_status_id, new_status_ids|
        numeric?(old_status_id) && new_status_ids.respond_to?(:keys) && new_status_ids.keys.all? { numeric?(it) }
      end
    end

    def to_hash(source)
      source.respond_to?(:to_unsafe_h) ? source.to_unsafe_h : source.to_h
    end

    def numeric?(key) = /\A\d+\z/.match?(key.to_s)

    def author? = tab == "author"

    def assignee? = tab == "assignee"
  end
end
