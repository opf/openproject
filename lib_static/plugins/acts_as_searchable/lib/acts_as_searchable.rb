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

module Redmine
  module Acts
    module Searchable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Options:
        # * :columns - a column or an array of columns to search
        # * :project_key - project foreign key (default to project_id)
        # * :date_column - name of the datetime column (default to created_at)
        # * :order_column - name of the column used to sort results (default to :date_column or created_at)
        # * :permission - permission required to search the model (default to :view_"objects")
        def acts_as_searchable(options = {})
          return if included_modules.include?(Redmine::Acts::Searchable::InstanceMethods)

          cattr_accessor :searchable_options
          self.searchable_options = options

          if searchable_options[:columns].nil?
            raise ArgumentError, "No searchable column defined."
          end

          searchable_options[:columns] = Array(searchable_options[:columns])
          searchable_options[:tsv_columns] ||= []

          searchable_options[:project_key] ||= "#{table_name}.project_id"
          searchable_options[:date_column] ||= "#{table_name}.created_at"
          searchable_options[:order_column] ||= searchable_options[:date_column]

          # Permission needed to search this model
          unless searchable_options.has_key?(:permission)
            searchable_options[:permission] =
              :"view_#{name.underscore.pluralize}"
          end

          # Should we search custom fields on this model ?
          searchable_options[:search_custom_fields] = !reflect_on_association(:custom_values).nil?

          searchable_options[:references] ||= []

          send :include, Redmine::Acts::Searchable::InstanceMethods
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend AddClassMethods
        end

        module AddClassMethods
          # Searches the model for the given tokens
          # projects argument can be either nil (will search all projects), a project or an array of projects
          # Returns the results and the results count
          def search(tokens, projects = nil, options = {})
            tokens = Array(tokens)
            projects = Array(projects) if projects

            find_conditions = build_find_conditions(tokens)

            project_conditions = [searchable_projects_condition]

            if projects
              project_conditions <<
                "#{searchable_options[:project_key]} IN (#{projects.flatten.map(&:id).join(',')})"
            end

            fetch_results(find_conditions, project_conditions, options)
          end

          private

          def build_find_conditions(tokens)
            sql, named_tokens = build_column_conditions_and_named_tokens(tokens)
            tsv_clauses = searchable_tsv_column_conditions(tokens)

            if tsv_clauses.any?
              sql << " OR #{tsv_clauses.join(' OR ')}"
            end

            [sql, named_tokens]
          end

          def searchable_projects_condition
            projects = if searchable_options[:permission].nil?
                         Project.visible(User.current)
                       else
                         Project.allowed_to(User.current, searchable_options[:permission])
                       end

            "#{searchable_options[:project_key]} IN (#{projects.select(:id).to_sql})"
          end

          def searchable_column_conditions
            searchable_options[:columns].map do |column|
              name, scope = column.is_a?(Hash) ? column.values_at(:name, :scope) : column
              match_condition = "(#{Arel.sql(name)} ILIKE ?)"

              if scope
                subquery_condition(scope, match_condition)
              else
                match_condition
              end
            end
          end

          def build_column_conditions_and_named_tokens(tokens)
            conditions = searchable_column_conditions

            if searchable_options[:search_custom_fields]
              conditions += Array(searchable_custom_fields_conditions)
            end

            substitute_named_tokens(tokens, conditions)
          end

          def substitute_named_tokens(tokens, conditions)
            sql = Array.new(tokens.size) do |index|
              "(#{conditions.join(' OR ').gsub('?', ":token_#{index}")})"
            end.join(" AND ")

            named_tokens = tokens.each_with_object({}).with_index do |(token, acc), index|
              acc[:"token_#{index}"] = "%#{sanitize_sql_like(token.downcase)}%"
            end

            [sql, named_tokens]
          end

          def searchable_tsv_column_conditions(tokens)
            searchable_options[:tsv_columns].filter_map do |tsv_column|
              tsv_condition =
                OpenProject::FullTextSearch.tsv_where(tsv_column[:table_name],
                                                      tsv_column[:column_name],
                                                      tokens.join(" "),
                                                      normalization: tsv_column[:normalization_type])
              if tsv_column[:scope]
                subquery_condition(tsv_column[:scope], tsv_condition)
              else
                tsv_condition
              end
            end
          end

          def searchable_custom_fields_conditions
            searchable_custom_field_ids = CustomField.where(type: "#{name}CustomField",
                                                            searchable: true).pluck(:id)
            return unless searchable_custom_field_ids.any?

            custom_field_condition = build_custom_field_condition(searchable_custom_field_ids)

            if name == "Project"
              # Filter out disabled project custom fields when searching for projects.
              custom_field_condition = add_project_custom_field_enabled_condition(custom_field_condition)
            end

            "EXISTS ( #{custom_field_condition.to_sql} )"
          end

          def build_custom_field_condition(custom_field_ids)
            CustomValue.select("1")
              .joins(<<~SQL.squish)
                LEFT JOIN custom_options
                ON custom_options.custom_field_id = custom_values.custom_field_id
                AND custom_options.id::VARCHAR = custom_values.value
              SQL
              .where(customized_type: name, custom_field_id: custom_field_ids)
              .where("customized_id=#{table_name}.id")
              .where("(custom_values.value ILIKE ?) OR (custom_options.value ILIKE ?)")
          end

          def add_project_custom_field_enabled_condition(scope)
            scope.joins(<<~SQL.squish)
              INNER JOIN project_custom_field_project_mappings
              ON project_custom_field_project_mappings.project_id = custom_values.customized_id
              AND project_custom_field_project_mappings.custom_field_id = custom_values.custom_field_id
            SQL
          end

          def subquery_condition(scope_clause, match_condition)
            raise ArgumentError, ":scope must be an instance of Proc" unless scope_clause.is_a?(Proc)

            scope = scope_clause.call
            unless scope.is_a?(ActiveRecord::Relation)
              raise ArgumentError, ":scope must return an instance of ActiveRecord::Relation"
            end

            "EXISTS ( #{scope.select('1').where(match_condition).to_sql} )"
          end

          def find_order(desc)
            "#{searchable_options[:order_column]} #{desc ? 'DESC' : 'ASC'}"
          end

          def fetch_results(find_conditions, project_conditions, options) # rubocop:disable Metrics/AbcSize
            results = []
            results_count = 0

            where(project_conditions.join(" AND ")).scoping do
              where(find_conditions)
                .includes(searchable_options[:include])
                .references(searchable_options[:references])
                .order(find_order(options[:before]))
                .scoping do
                  results_count = count
                  results       = all

                  if options[:offset]
                    results = results.where(
                      "(#{searchable_options[:date_column]} " +
                      (options[:before] ? "<" : ">") +
                      "'#{connection.quoted_date(options[:offset])}')"
                    )
                  end
                  results = results.limit(options[:limit]) if options[:limit]
                end
            end

            [results, results_count]
          end
        end
      end
    end
  end
end
