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
    module Activities
      class ActivityEagerLoadingWrapper < API::V3::Utilities::EagerLoading::EagerLoadingWrapper
        class << self
          def wrap(journals)
            if journals.any?
              set_journable(journals)
              set_predecessor(journals)
              set_data(journals)
            end

            super
          end

          private

          def set_journable(journals)
            journables = journable_by_type_and_id(journals)

            journals.each do |journal|
              journal.journable = journables[journal.journable_type][journal.journable_id]
            end
          end

          def set_predecessor(journals)
            predecessors = predecessors_by_type_and_id(journals)

            journals.each do |journal|
              next unless predecessors[journal.journable_type]

              predecessor = predecessors[journal.journable_type][journal.journable_id]&.find { |j| j.version < journal.version }

              journal.instance_variable_set(:@predecessor, predecessor)
            end
          end

          def set_data(journals)
            data = data_by_type_and_id(journals)

            journals.each do |journal|
              journal.data = data[journal.data_type][journal.data_id]
              journal.previous.data = data[journal.data_type][journal.previous.data_id] if journal.previous.present?
            end
          end

          def journable_by_type_and_id(journals)
            journals
              .group_by(&:journable_type)
              .each_with_object({}) do |(journable_type, journable_type_journals), hash|
                journable_ids = journable_type_journals.map(&:journable_id).uniq
                hash[journable_type] = journable_type
                                         .constantize
                                         .where(id: journable_ids)
                                         .includes(includes_for(journable_type))
                                         .index_by(&:id)
              end
          end

          def includes_for(journable_type)
            journable_type == "Project" ? [:project_custom_field_project_mappings] : [:project]
          end

          def data_by_type_and_id(journals)
            # Assuming that
            # * the journable has already been loaded by #set_journable
            # * previous has already been loaded by #set_predecessor
            journals
              .group_by(&:data_type)
              .each_with_object({}) do |(data_type, data_type_journals), hash|
                hash[data_type] = data_type
                                    .constantize
                                    .find(data_ids(data_type_journals))
                                    .index_by(&:id)
              end
          end

          def predecessors_by_type_and_id(journals)
            predecessor_journals(journals)
              .group_by(&:journable_type)
              .transform_values do |v|
              v
                .group_by(&:journable_id)
                .transform_values { |j| j.sort_by(&:version).reverse }
            end
          end

          def data_ids(journals)
            journals.map { |j| [j.data_id, j.previous&.data_id] }.flatten.compact
          end

          def predecessor_journals(journals)
            current = journals.map { |j| [j.journable_type, j.journable_id, j.version] }

            Journal
              .from(
                <<~SQL.squish
                  (SELECT DISTINCT ON (predecessors.journable_type, predecessors.journable_id, current.version)
                    predecessors.*
                  FROM
                    #{Journal.arel_table.grouping(Arel::Nodes::ValuesList.new(current)).as('current(journable_type, journable_id, version)').to_sql}
                  JOIN journals predecessors
                    ON current.journable_type = predecessors.journable_type
                    AND current.journable_id = predecessors.journable_id
                    AND current.version > predecessors.version
                  ORDER BY predecessors.journable_type, predecessors.journable_id, current.version, predecessors.version DESC
                  ) AS journals
                SQL
              )
              .includes(:attachable_journals, :customizable_journals, :storable_journals)
          end
        end
      end
    end
  end
end
