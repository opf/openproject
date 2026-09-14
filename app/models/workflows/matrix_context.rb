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
  # The matrix edits one named variant, held below as `variant`. Every configuration read here
  # is that variant's own: an admin editing a variant means that variant, not whatever a
  # project would resolve to.
  class MatrixContext
    TABS = %w[always author assignee].freeze
    DEFAULT_TAB = "always"

    attr_reader :variant

    def initialize(variant:, tab: nil, role_ids: nil, status_ids: nil, displayed_status_ids: nil)
      @variant = variant
      @requested_tab = tab
      @requested_role_ids = role_ids
      @requested_status_ids = status_ids_from(status_ids)
      @displayed_status_ids = status_ids_from(displayed_status_ids)
    end

    # Normalised, so that rendering, the status query and persistence cannot disagree
    # about which tab is being edited. The raw value is absent whenever the matrix is
    # opened without one.
    def tab
      @tab ||= TABS.include?(@requested_tab.to_s) ? @requested_tab.to_s : DEFAULT_TAB
    end

    def readonly? = variant.linked?(TypeVariant::WORKFLOWS)

    def eligible_roles
      @eligible_roles ||= Workflow.ordered_eligible_roles
    end

    def roles
      @roles ||= Workflow.selected_roles(@requested_role_ids)
    end

    # The dialogs forward these verbatim, so they must stay the raw request and never fall
    # back to the saved statuses the way #statuses does.
    attr_reader :requested_status_ids

    # The axes of the matrix.
    def statuses
      @statuses ||= if requested_status_ids.present?
                      Status.where(id: requested_status_ids).order(:position)
                    elsif roles.any?
                      Status.where(id: saved_status_ids)
                    else
                      variant.statuses
                    end
    end

    # Statuses the dialog added but which have no transitions yet, so the matrix can
    # pre-check their pairs instead of rendering them indeterminate.
    def added_status_ids
      return [] if requested_status_ids.blank?

      @added_status_ids ||= requested_status_ids - saved_status_ids
    end

    # Statuses that saving the pending selection would drop from the variant, deleting their
    # transitions along with them.
    def removed_status_ids
      return [] if requested_status_ids.blank?

      @removed_status_ids ||= saved_status_ids - requested_status_ids
    end

    # The removals of a single dialog turn, measured against the statuses the dialog was
    # rendered with instead of against the database. This is what the removal dialog asks
    # about: taking out a status that is not saved yet still counts, and a removal already
    # confirmed is not counted a second time.
    #
    # Only the dialog's own submit carries that baseline; every other request leaves this
    # empty, which is why #status_changes? compares against what is saved instead.
    def removed_displayed_status_ids
      @removed_displayed_status_ids ||= @displayed_status_ids - requested_status_ids
    end

    # Whether the pending selection differs from what is saved, which the matrix uses to
    # warn before navigating away.
    def status_changes?
      added_status_ids.any? || removed_status_ids.any?
    end

    def workflows
      @workflows ||= variant
                       .workflows
                       .where(role_id: roles.map(&:id))
                       .select { belongs_to_tab?(it) }
    end

    private

    def status_ids_from(ids)
      Array(ids).flatten.map(&:to_i)
    end

    def belongs_to_tab?(workflow)
      case tab
      when "author" then workflow.author
      when "assignee" then workflow.assignee
      else !workflow.author && !workflow.assignee
      end
    end

    # The baseline a pending selection is compared against: always what the selected roles
    # have saved, never the pending selection itself.
    def saved_status_ids
      @saved_status_ids ||= roles.flat_map { variant.statuses(role: it, tab:).pluck(:id) }.uniq
    end
  end
end
