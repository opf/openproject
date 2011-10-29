#-- encoding: UTF-8
# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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
        # * :date_column - name of the datetime column (default to created_on)
        # * :sort_order - name of the column used to sort results (default to :date_column or created_on)
        # * :permission - permission required to search the model (default to :view_"objects")
        def acts_as_searchable(options = {})
          return if self.included_modules.include?(Redmine::Acts::Searchable::InstanceMethods)
  
          cattr_accessor :searchable_options
          self.searchable_options = options

          if searchable_options[:columns].nil?
            raise 'No searchable column defined.'
          elsif !searchable_options[:columns].is_a?(Array)
            searchable_options[:columns] = [] << searchable_options[:columns]
          end

          searchable_options[:project_key] ||= "#{table_name}.project_id"
          searchable_options[:date_column] ||= "#{table_name}.created_on"
          searchable_options[:order_column] ||= searchable_options[:date_column]
          
          # Permission needed to search this model
          searchable_options[:permission] = "view_#{self.name.underscore.pluralize}".to_sym unless searchable_options.has_key?(:permission)
          
          # Should we search custom fields on this model ?
          searchable_options[:search_custom_fields] = !reflect_on_association(:custom_values).nil?
          
          send :include, Redmine::Acts::Searchable::InstanceMethods
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          # Searches the model for the given tokens
          # projects argument can be either nil (will search all projects), a project or an array of projects
          # Returns the results and the results count
          def search(tokens, projects=nil, options={})
            tokens = [] << tokens unless tokens.is_a?(Array)
            projects = [] << projects unless projects.nil? || projects.is_a?(Array)
            
            find_options = {:include => searchable_options[:include]}
            find_options[:order] = "#{searchable_options[:order_column]} " + (options[:before] ? 'DESC' : 'ASC')
            
            limit_options = {}
            limit_options[:limit] = options[:limit] if options[:limit]
            if options[:offset]
              limit_options[:conditions] = "(#{searchable_options[:date_column]} " + (options[:before] ? '<' : '>') + "'#{connection.quoted_date(options[:offset])}')"
            end
            
            columns = searchable_options[:columns]
            columns = columns[0..0] if options[:titles_only]
            
            token_clauses = columns.collect {|column| "(LOWER(#{column}) LIKE ?)"}
            
            if !options[:titles_only] && searchable_options[:search_custom_fields]
              searchable_custom_field_ids = CustomField.find(:all,
                                                             :select => 'id',
                                                             :conditions => { :type => "#{self.name}CustomField",
                                                                              :searchable => true }).collect(&:id)
              if searchable_custom_field_ids.any?
                custom_field_sql = "#{table_name}.id IN (SELECT customized_id FROM #{CustomValue.table_name}" +
                  " WHERE customized_type='#{self.name}' AND customized_id=#{table_name}.id AND LOWER(value) LIKE ?" +
                  " AND #{CustomValue.table_name}.custom_field_id IN (#{searchable_custom_field_ids.join(',')}))"
                token_clauses << custom_field_sql
              end
            end
            
            sql = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')
            
            find_options[:conditions] = [sql, * (tokens.collect {|w| "%#{w.downcase}%"} * token_clauses.size).sort]
            
            project_conditions = []
            project_conditions << (searchable_options[:permission].nil? ? Project.visible_by(User.current) :
                                                 Project.allowed_to_condition(User.current, searchable_options[:permission]))
            project_conditions << "#{searchable_options[:project_key]} IN (#{projects.collect(&:id).join(',')})" unless projects.nil?
            
            results = []
            results_count = 0
            
            with_scope(:find => {:conditions => project_conditions.join(' AND ')}) do
              with_scope(:find => find_options) do
                results_count = count(:all)
                results = find(:all, limit_options)
              end
            end
            [results, results_count]
          end
        end
      end
    end
  end
end
