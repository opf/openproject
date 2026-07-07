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

module Projects::Copy
  class BacklogBucketsDependentService < Dependency
    def self.human_name
      I18n.t("projects.copy.backlog_buckets")
    end

    def source_count
      source.backlog_buckets.count
    end

    protected

    def copy_dependency(*)
      backlog_bucket_id_map = {}

      source.backlog_buckets.each do |source_bucket|
        attributes = source_bucket.attributes.dup.except("id", "project_id", "created_at", "updated_at")
        bucket = target.backlog_buckets.create!(attributes)
        backlog_bucket_id_map[source_bucket.id] = bucket.id

        # Re-assigned on every iteration (rather than once after the loop) because `state` is a
        # Hashie::Mash: assignment converts the Hash into a new Mash, breaking object identity, so
        # later mutations of `backlog_bucket_id_map` alone would not be visible through
        # `state.backlog_bucket_id_lookup`. Keeping the lookup current after each bucket also means a
        # mid-loop `create!` failure (rescued by `Copy::Dependency#perform`) leaves the partial
        # mapping intact instead of nil.
        state.backlog_bucket_id_lookup = backlog_bucket_id_map
      end
    end
  end
end
