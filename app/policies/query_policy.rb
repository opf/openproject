#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# This capsulates permissions a user has for a work package.  It caches based
# on the work package's project and is thus optimized for the context menu.
#
# This is no conern but it was placed here so that it will be removed together
# with the rest of the experimental API.

class QueryPolicy < BasePolicy
  private

  def cache(query)
    @cache ||= Hash.new do |hash, cached_query|
      hash[cached_query] = {
        show: viewable?(cached_query),
        update: persisted_and_own_or_public?(cached_query),
        destroy: persisted_and_own_or_public?(cached_query),
        create: create_allowed?(cached_query),
        publicize: publicize_allowed?(cached_query),
        depublicize: depublicize_allowed?(cached_query),
        star: persisted_and_own_or_public?(cached_query),
        unstar: persisted_and_own_or_public?(cached_query)
      }
    end

    @cache[query]
  end

  def persisted_and_own_or_public?(query)
    query.persisted? &&
      (save_queries_allowed?(query) && query.user == user ||
       manage_public_queries_allowed?(query) && query.is_public)
  end

  def viewable?(query)
    view_work_packages_allowed?(query) &&
      (query.is_public? || query.user == user)
  end

  def create_allowed?(query)
    query.new_record? &&
      save_queries_allowed?(query)
  end

  def publicize_allowed?(query)
    !query.is_public &&
      query.user_id == user.id &&
      manage_public_queries_allowed?(query)
  end

  def depublicize_allowed?(query)
    query.is_public &&
      manage_public_queries_allowed?(query)
  end

  def view_work_packages_allowed?(query)
    @view_work_packages_cache ||= Hash.new do |hash, project|
      hash[project] = user.allowed_to?(:view_work_packages, project, global: project.nil?)
    end

    @view_work_packages_cache[query.project]
  end

  def save_queries_allowed?(query)
    @save_queries_cache ||= Hash.new do |hash, project|
      hash[project] = user.allowed_to?(:save_queries, project, global: project.nil?)
    end

    @save_queries_cache[query.project]
  end

  def manage_public_queries_allowed?(query)
    @manage_public_queries_cache ||= Hash.new do |hash, project|
      hash[project] = user.allowed_to?(:manage_public_queries, project, global: project.nil?)
    end

    @manage_public_queries_cache[query.project]
  end
end
