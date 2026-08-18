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

class PlaceholderUser < Principal
  alias_attribute(:name, :lastname)

  validates(:name, presence: true)
  validates(:name, uniqueness: true)
  validates :name, length: { maximum: 256 }

  include ::Associations::Groupable

  has_details_table(foreign_key: :principal_id) do
    # Deferred: loading UserQuery reads the schema, which fails during db:create.
    serialize :user_filter, coder: Queries::Serialization::Filters.new(-> { UserQuery })
  end

  has_many :resource_allocations,
           class_name: "ResourceAllocation",
           dependent: :restrict_with_error,
           inverse_of: :placeholder_user

  scopes :visible

  # Columns required for formatting the placeholder user's name.
  def self.columns_for_name(_formatter = nil)
    [:lastname]
  end

  def to_s
    lastname
  end

  # Resolves the candidate counts for many placeholders in one round trip, so a
  # list rendering "N matching users" per row does not fire a query per row.
  def self.preload_candidate_counts(placeholders, project: nil)
    persisted = Array(placeholders).select(&:persisted?)
    counts = candidate_counts_by_id(persisted, project)

    persisted.each do |placeholder|
      placeholder.write_candidate_count(project, counts.fetch(placeholder.id, 0))
    end
  end

  def self.candidate_counts_by_id(placeholders, project)
    selects = placeholders.filter_map { |placeholder| candidate_count_select(placeholder, project) }
    return {} if selects.empty?

    connection
      .select_rows(selects.join(" UNION ALL "))
      .to_h { |id, count| [id.to_i, count.to_i] }
  end
  private_class_method :candidate_counts_by_id

  def self.candidate_count_select(placeholder, project)
    candidates = placeholder.candidate_query(project:).results.reselect(:id).unscope(:order).to_sql

    "SELECT #{connection.quote(placeholder.id)} AS id, COUNT(*) AS count FROM (#{candidates}) candidates"
  rescue StandardError => e
    Rails.logger.warn("Candidate query for placeholder user #{placeholder.id} failed: #{e.class}: #{e.message}")
    nil
  end
  private_class_method :candidate_count_select

  # Scoped to the current user via UserQuery's default scope. The membership
  # filter is applied last so a `member` value in the stored filter cannot
  # widen the project narrowing.
  def candidate_query(project: nil)
    UserQuery.new.tap do |query|
      user_filter.each do |filter|
        query.where(filter.field, filter.operator, filter.values)
      end

      query.where(:member, "=", [project.id.to_s]) if project
    end
  end

  def candidate_count(project: nil)
    key = project&.id

    candidate_counts.fetch(key) { candidate_counts[key] = resolve_candidate_count(project) }
  end

  def write_candidate_count(project, count)
    candidate_counts[project&.id] = count
  end

  private

  # An incompletely configured filter must not take down the whole view.
  def resolve_candidate_count(project)
    candidate_query(project:).results.count
  rescue StandardError => e
    Rails.logger.warn("Candidate count for placeholder user #{id} failed: #{e.class}: #{e.message}")
    0
  end

  def candidate_counts
    @candidate_counts ||= {}
  end
end
