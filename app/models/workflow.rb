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

class Workflow < ApplicationRecord
  # The project owning this workflow, or nil for a workflow every project may use.
  belongs_to :project, optional: true

  has_many :type_variants, dependent: :restrict_with_error, inverse_of: :workflow
  has_many :status_transitions,
           class_name: "Workflows::StatusTransition",
           inverse_of: :workflow,
           dependent: :delete_all

  validates :name, presence: true, length: { maximum: 255 }
  validates :name, uniqueness: { scope: :project_id, case_sensitive: false }
  validates :description, length: { maximum: 255 }

  scope :in_display_order, -> { order(Arel.sql("LOWER(name) ASC")) }

  scope :global, -> { where(project_id: nil) }
  scope :project_owned, -> { where.not(project_id: nil) }
  scope :owned_by, ->(project) { where(project:) }
  scope :available_in, ->(project) { where(project: [nil, project]) }

  scope :with_name_like, ->(query) {
    where("name ILIKE :query", query: "%#{sanitize_sql_like(query.to_s.strip)}%")
  }

  def self.build_with_available_name(base, project: nil, **attributes)
    new(name: available_name(base, project:), project:, **attributes)
  end

  # A name only has to be free within the scope that will hold it, so a project may reuse one
  # administration already has.
  def self.available_name(base, project: nil)
    base = base.to_s.strip.presence || I18n.t("workflows.name.fallback")
    taken = owned_by(project)
    return base unless taken.exists?(["LOWER(name) = LOWER(?)", base])

    suffix = 2
    suffix += 1 while taken.exists?(["LOWER(name) = LOWER(?)", "#{base} (#{suffix})"])
    "#{base} (#{suffix})"
  end

  def self.statuses(workflows, role: nil, tab: nil) # rubocop:disable Metrics/AbcSize
    transition_table, status_table = [Workflows::StatusTransition, Status].map(&:arel_table)
    ids = workflows.respond_to?(:arel) ? workflows.arel : workflows
    old_id_subselect, new_id_subselect = %i[old_status_id new_status_id].map do |foreign_key|
      subquery = transition_table.project(transition_table[foreign_key])
                                 .where(transition_table[:workflow_id].in(ids))
      subquery = subquery.where(transition_table[:role_id].eq(role.id)) if role
      subquery = apply_tab_condition(subquery, transition_table, tab) if tab
      subquery
    end
    Status.where(status_table[:id].in(old_id_subselect).or(status_table[:id].in(new_id_subselect)))
  end

  def self.apply_tab_condition(subquery, transition_table, tab)
    case tab
    when "author"
      subquery.where(transition_table[:author].eq(true))
    when "assignee"
      subquery.where(transition_table[:assignee].eq(true))
    else
      subquery.where(transition_table[:author].eq(false).and(transition_table[:assignee].eq(false)))
    end
  end

  def statuses(role: nil, tab: nil)
    return Status.none if new_record?

    self.class.statuses([id], role:, tab:)
  end

  def used_by_one_variant?
    type_variants.one?
  end

  def project_specific? = project_id.present?
end
