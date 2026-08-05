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

module API
  module V3
    module WorkPackages
      module EagerLoading
        class Checksum < Base
          def apply(work_package)
            work_package.cache_checksum = cache_checksum_of(work_package)
          end

          def self.module
            CacheChecksumAccessor
          end

          class << self
            def for(work_package)
              fetch_checksums_for(Array(work_package))[work_package.id]
            end

            def fetch_checksums_for(work_packages)
              WorkPackage
                .where(id: work_packages.map(&:id).uniq)
                .left_joins(*checksum_associations)
                .pluck("work_packages.id", Arel.sql(md5_concat.squish))
                .to_h
            end

            protected

            # The versions associated via work_package_versions are a has_many,
            # which the left_joins/pluck design above cannot express (it would
            # multiply rows), so they enter the checksum as an aggregated
            # correlated subquery. This also covers versions beyond the first,
            # which the deprecated version association could not see.
            # Every kind is folded in, since the representer renders both the
            # target (as `version` and `targetVersions`) and the observed_in
            # rows (as `observedInVersions`). The kind is part of the aggregated
            # value so that moving a version between kinds busts the cache too.
            # The parts are separated so that no two distinct tuples can
            # concatenate to the same string and collide.
            VERSIONS_CHECKSUM_SQL = <<~SQL.squish
              (SELECT COALESCE(STRING_AGG(CONCAT_WS('-', wpv.kind, v.id, v.updated_at), ',' ORDER BY wpv.kind, v.id), '')
                 FROM work_package_versions wpv
                 INNER JOIN versions v ON v.id = wpv.version_id
                WHERE wpv.work_package_id = work_packages.id)
            SQL

            # Same reasoning as VERSIONS_CHECKSUM_SQL: the categories are a
            # has_many that the left_joins/pluck design cannot express, and the
            # representer renders every one of them (as `categories`), not just
            # the one the deprecated category association can see.
            # The parts are separated so that no two distinct tuples can
            # concatenate to the same string and collide.
            CATEGORIES_CHECKSUM_SQL = <<~SQL.squish
              (SELECT COALESCE(STRING_AGG(CONCAT_WS('-', c.id, c.updated_at), ',' ORDER BY c.id), '')
                 FROM work_package_categories wpc
                 INNER JOIN categories c ON c.id = wpc.category_id
                WHERE wpc.work_package_id = work_packages.id)
            SQL

            def md5_concat
              md5_parts = checksum_associations.flat_map do |association_name|
                table_name = md5_checksum_table_name(association_name)

                %W[#{table_name}.id #{table_name}.updated_at]
              end
              md5_parts << VERSIONS_CHECKSUM_SQL
              md5_parts << CATEGORIES_CHECKSUM_SQL

              <<-SQL
                MD5(CONCAT(#{md5_parts.join(', ')}))
              SQL
            end

            def checksum_associations
              %i[status author responsible assigned_to priority category type budget]
            end

            def md5_checksum_table_name(association_name)
              case association_name
              when :responsible
                "responsibles_work_packages"
              when :assigned_to
                "assigned_tos_work_packages"
              else
                association_class(association_name).table_name
              end
            end

            def association_class(association_name)
              WorkPackage.reflect_on_association(association_name).class_name.constantize
            end
          end

          private

          def cache_checksum_of(work_package)
            cache_checksums[work_package.id]
          end

          def cache_checksums
            @cache_checksums ||= self.class.fetch_checksums_for(work_packages)
          end
        end

        module CacheChecksumAccessor
          extend ActiveSupport::Concern

          included do
            attr_accessor :cache_checksum
          end
        end
      end
    end
  end
end
