#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class QueryPolicy < BasePolicy
  private

  def cache(query)
    @cache ||= Hash.new do |hash, cached_query|
      hash[cached_query] = {
        show: viewable?(cached_query),
        update: persisted_and_own_or_public?(cached_query),
        destroy: persisted_and_own_or_public?(cached_query),
        create: create_allowed?(cached_query),
        create_new: create_new_allowed?(cached_query),
        publicize: publicize_allowed?(cached_query),
        depublicize: depublicize_allowed?(cached_query),
        star: persisted_and_own_or_public?(cached_query),
        unstar: persisted_and_own_or_public?(cached_query),
        reorder_work_packages: reorder_work_packages?(cached_query),
        share_via_ical: share_via_ical_allowed?(cached_query)
      }
    end

    @cache[query]
  end

  def persisted_and_own_or_public?(query)
    query.persisted? &&
      (
        (save_queries_allowed?(query) && query.user == user) ||
        public_manageable_query?(query)
      )
  end

  def viewable?(query)
    view_work_packages_allowed?(query) &&
      (query.public? || query.user == user)
  end

  def create_allowed?(query)
    query.new_record? && create_new_allowed?(query)
  end

  def create_new_allowed?(query)
    save_queries_allowed?(query)
  end

  def publicize_allowed?(query)
    !query.public &&
      query.user_id == user.id &&
      manage_public_queries_allowed?(query)
  end

  def depublicize_allowed?(query)
    public_manageable_query?(query)
  end

  def public_manageable_query?(query)
    query.public &&
      manage_public_queries_allowed?(query)
  end

  def reorder_work_packages?(query)
    persisted_and_own_or_public?(query) || edit_work_packages_allowed?(query)
  end

  def view_work_packages_allowed?(query)
    if query.project
      user.allowed_in_any_work_package?(:view_work_packages, in_project: query.project)
    else
      user.allowed_in_any_work_package?(:view_work_packages)
    end
  end

  def edit_work_packages_allowed?(query)
    user.allowed_in_any_work_package?(:edit_work_packages, in_project: query.project)
  end

  def save_queries_allowed?(query)
    if query.project
      user.allowed_in_project?(:save_queries, query.project)
    else
      user.allowed_in_any_project?(:save_queries)
    end
  end

  def manage_public_queries_allowed?(query)
    if query.project
      user.allowed_in_project?(:manage_public_queries, query.project)
    else
      user.allowed_in_any_project?(:manage_public_queries)
    end
  end

  def share_via_ical_allowed?(query)
    if query.project
      user.allowed_in_project?(:share_calendars, query.project)
    else
      user.allowed_in_any_project?(:share_calendars)
    end
  end
end
