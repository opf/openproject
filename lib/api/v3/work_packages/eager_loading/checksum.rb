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

            # Versions are a has_many, which would multiply rows in the
            # left_joins/pluck above, so they enter as an aggregated subquery.
            # A version can attach under more than one kind, so the kind is part
            # of the value and of the order.
            VERSIONS_CHECKSUM_SQL = <<~SQL.squish
              (SELECT COALESCE(STRING_AGG(CONCAT(wpv.kind, v.id, v.updated_at), ',' ORDER BY wpv.kind, v.id), '')
                 FROM work_package_versions wpv
                 INNER JOIN versions v ON v.id = wpv.version_id
                WHERE wpv.work_package_id = work_packages.id)
            SQL

            def md5_concat
              md5_parts = checksum_associations.flat_map do |association_name|
                table_name = md5_checksum_table_name(association_name)

                %W[#{table_name}.id #{table_name}.updated_at]
              end
              md5_parts << VERSIONS_CHECKSUM_SQL

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
