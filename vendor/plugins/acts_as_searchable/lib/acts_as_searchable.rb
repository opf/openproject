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
        def acts_as_searchable(options = {})
          return if self.included_modules.include?(Redmine::Acts::Searchable::InstanceMethods)
  
          cattr_accessor :searchable_options
          self.searchable_options = options

          if searchable_options[:columns].nil?
            raise 'No searchable column defined.'
          elsif !searchable_options[:columns].is_a?(Array)
            searchable_options[:columns] = [] << searchable_options[:columns]
          end

          if searchable_options[:project_key]
          elsif column_names.include?('project_id')
            searchable_options[:project_key] = "#{table_name}.project_id"
          else
            raise 'No project key defined.'
          end
          
          if searchable_options[:date_column]
          elsif column_names.include?('created_on')
            searchable_options[:date_column] = "#{table_name}.created_on"
          else
            raise 'No date column defined defined.'
          end
          
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
          # Search the model for the given tokens
          # projects argument can be either nil (will search all projects), a project or an array of projects
          def search(tokens, projects=nil, options={})
            tokens = [] << tokens unless tokens.is_a?(Array)
            projects = [] << projects unless projects.nil? || projects.is_a?(Array)
            
            find_options = {:include => searchable_options[:include]}
            find_options[:limit] = options[:limit] if options[:limit]
            find_options[:order] = "#{searchable_options[:date_column]} " + (options[:before] ? 'DESC' : 'ASC')
            columns = searchable_options[:columns]
            columns.slice!(1..-1) if options[:titles_only]
            
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
            
            if options[:offset]
              sql = "(#{sql}) AND (#{searchable_options[:date_column]} " + (options[:before] ? '<' : '>') + "'#{connection.quoted_date(options[:offset])}')"
            end
            find_options[:conditions] = [sql, * (tokens * token_clauses.size).sort]
            
            project_conditions = []
            project_conditions << (searchable_options[:permission].nil? ? Project.visible_by(User.current) :
                                                 Project.allowed_to_condition(User.current, searchable_options[:permission]))
            project_conditions << "#{searchable_options[:project_key]} IN (#{projects.collect(&:id).join(',')})" unless projects.nil?
            
            results = with_scope(:find => {:conditions => project_conditions.join(' AND ')}) do
              find(:all, find_options)
            end            
            if searchable_options[:with] && !options[:titles_only]
              searchable_options[:with].each do |model, assoc|
                results += model.to_s.camelcase.constantize.search(tokens, projects, options).collect {|r| r.send assoc}
              end
              results.uniq!
            end
            results
          end
        end
      end
    end
  end
end
