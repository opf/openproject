#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
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
              concat = if OpenProject::Database.mysql?
                         md5_concat_mysql
                       else
                         md5_concat_postgresql
                       end

              WorkPackage
                .where(id: work_packages.map(&:id).uniq)
                .left_joins(:status, :author, :responsible, :assigned_to, :fixed_version, :priority, :category, :type)
                .pluck('work_packages.id', Arel.sql(concat.squish))
                .to_h
            end

            protected

            def md5_concat_postgresql
              <<-SQL
                MD5(CONCAT(statuses.id,
                           statuses.updated_at,
                           users.id,
                           users.updated_on,
                           responsibles_work_packages.id,
                           responsibles_work_packages.updated_on,
                           assigned_tos_work_packages.id,
                           assigned_tos_work_packages.updated_on,
                           versions.id,
                           versions.updated_on,
                           types.id,
                           types.updated_at,
                           enumerations.id,
                           enumerations.updated_at,
                           categories.id,
                           categories.updated_at))
              SQL
            end

            def md5_concat_mysql
              <<-SQL
                MD5(CONCAT(COALESCE(statuses.id, 0),
                           COALESCE(statuses.updated_at, '-'),
                           COALESCE(users.id, '-'),
                           COALESCE(users.updated_on, '-'),
                           COALESCE(responsibles_work_packages.id, '-'),
                           COALESCE(responsibles_work_packages.updated_on, '-'),
                           COALESCE(assigned_tos_work_packages.id, '-'),
                           COALESCE(assigned_tos_work_packages.updated_on, '-'),
                           COALESCE(versions.id, '-'),
                           COALESCE(versions.updated_on, '-'),
                           COALESCE(types.id, '-'),
                           COALESCE(types.updated_at, '-'),
                           COALESCE(enumerations.id, '-'),
                           COALESCE(enumerations.updated_at, '-'),
                           COALESCE(categories.id, '-'),
                           COALESCE(categories.updated_at, '-')))
              SQL
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
