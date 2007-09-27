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
          
          send :include, Redmine::Acts::Searchable::InstanceMethods
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def search(tokens, all_tokens, project, options={})
            tokens = [] << tokens unless tokens.is_a?(Array)
            find_options = {:include => searchable_options[:include]}
            find_options[:limit] = options[:limit] if options[:limit]
            find_options[:order] = "#{searchable_options[:date_column]} " + (options[:before] ? 'DESC' : 'ASC')

            sql = ([ '(' + searchable_options[:columns].collect {|column| "(LOWER(#{column}) LIKE ?)"}.join(' OR ') + ')' ] * tokens.size).join(all_tokens ? ' AND ' : ' OR ')
            if options[:offset]
              sql = "(#{sql}) AND (#{searchable_options[:date_column]} " + (options[:before] ? '<' : '>') + "'#{connection.quoted_date(options[:offset])}')"
            end
            find_options[:conditions] = [sql, * (tokens * searchable_options[:columns].size).sort]
            
            results = with_scope(:find => {:conditions => ["#{searchable_options[:project_key]} = ?", project.id]}) do
              find(:all, find_options)
            end            
            if searchable_options[:with]
              searchable_options[:with].each do |model, assoc|
                results += model.to_s.camelcase.constantize.search(tokens, all_tokens, project, options).collect {|r| r.send assoc}
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
