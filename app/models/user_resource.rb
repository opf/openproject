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

# A reusable, named description of the kind of person a resource allocation
# asks for ("Senior Developer, speaks DE or EN"). It is a Principal so it can
# be referenced, rendered and picked like any other party, but it is never a
# human: it cannot log in, cannot be a member and holds no custom fields.
#
# What it *is* defined by is the user filter, because the matching rules need
# boolean structure that custom field values cannot express — `languages` being
# "DE or EN" versus "DE and EN" is a difference in the filter operator, not in
# the stored values.
class UserResource < Principal
  alias_attribute(:name, :lastname)

  validates(:name, presence: true)
  validates(:name, uniqueness: true)
  validates :name, length: { maximum: 256 }

  has_details_table(foreign_key: :principal_id) do
    # Deferred: the API mounts this model at boot, and loading UserQuery reads
    # the schema, which fails while there is no database yet (db:create).
    serialize :user_filter, coder: Queries::Serialization::Filters.new(-> { UserQuery })

    # A resource without filters would match every user in the instance, which
    # is never what someone means to request.
    validates :user_filter, presence: true
  end

  has_many :resource_allocations,
           class_name: "ResourceAllocation",
           dependent: :restrict_with_error,
           inverse_of: :user_resource

  scopes :visible

  # Columns required for formatting the user resource's name.
  def self.columns_for_name(_formatter = nil)
    [:lastname]
  end

  def to_s
    lastname
  end

  # Resolves the candidate counts for many resources in a single round trip and
  # stashes them on the records, so a list rendering "N matching users" per row
  # does not fire one query per row. Each resource carries its own stored filter,
  # so the counts cannot be expressed as a scope over `user_resources` — the
  # per-resource queries are unioned instead.
  #
  # A resource whose filter cannot be resolved is left out of the union and falls
  # back to zero, so one broken filter never takes down the whole list.
  def self.preload_candidate_counts(resources, project: nil)
    persisted = Array(resources).select(&:persisted?)
    counts = candidate_counts_by_id(persisted, project)

    persisted.each do |resource|
      resource.write_candidate_count(project, counts.fetch(resource.id, 0))
    end
  end

  def self.candidate_counts_by_id(resources, project)
    selects = resources.filter_map { |resource| candidate_count_select(resource, project) }
    return {} if selects.empty?

    connection
      .select_rows(selects.join(" UNION ALL "))
      .to_h { |id, count| [id.to_i, count.to_i] }
  end
  private_class_method :candidate_counts_by_id

  def self.candidate_count_select(resource, project)
    candidates = resource.candidate_query(project:).results.reselect(:id).unscope(:order).to_sql

    "SELECT #{connection.quote(resource.id)} AS id, COUNT(*) AS count FROM (#{candidates}) candidates"
  rescue StandardError => e
    Rails.logger.warn("Candidate query for user resource #{resource.id} failed: #{e.class}: #{e.message}")
    nil
  end
  private_class_method :candidate_count_select

  # The users this resource stands for. `UserQuery`'s default scope is
  # `User.user.visible`, so the result is always scoped to the current user —
  # callers that need the instance-wide count have to say so explicitly.
  #
  # Passing a project narrows the candidates to its members. The membership
  # filter is applied last, so a `member` value smuggled into the stored filter
  # is overwritten rather than honoured.
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

  # Resolving a stored filter can fail when it is incompletely configured; a
  # single broken resource must not take down the view it is rendered in.
  def resolve_candidate_count(project)
    candidate_query(project:).results.count
  rescue StandardError => e
    Rails.logger.warn("Candidate count for user resource #{id} failed: #{e.class}: #{e.message}")
    0
  end

  def candidate_counts
    @candidate_counts ||= {}
  end
end
