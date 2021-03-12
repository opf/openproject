#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
  module Decorators
    class SqlRepresenter
      extend ::API::V3::Utilities::PathHelper

      class_attribute :properties,
                      :association_links,
                      :links

      class << self
        # Properties
        def properties_sql(select)

          properties
            .slice(*cleaned_selects(select))
            .map do |name, options|
            representation = if options[:representation]
                               options[:representation].call
                             else
                               "#{options[:column]}"
                             end

            "'#{name}', #{representation}"
          end.join(', ')
        end

        def property(name,
                     column: name,
                     representation: nil,
                     render_if: nil)
          self.properties ||= {}

          properties[name] = { column: column, render_if: render_if, representation: representation }
        end

        def properties_conditions
          properties
            .select { |_, options| options[:render_if] }
            .map do |name, options|
            "- CASE WHEN #{options[:render_if].call} THEN '' ELSE '#{name}' END"
          end.join(' ')
        end

        # TODO: turn association_link into separate class so that
        # instances can be generated here
        def association_link(name, column: name, path: nil, join:, title: nil, href: nil)
          self.association_links ||= {}

          association_links[name] = { column: column,
                                      path: path,
                                      join: join,
                                      title: title,
                                      href: href }
        end

        def joins(select, scope)
          self.association_links ||= {}
          self.links ||= {}

          (links.merge(association_links))
            .slice(*cleaned_selects(select))
            .select { |_, link| link[:join] }
            .map do |name, link|
            column = link[:column] ? link[:column].call : "#{name}_id"

            join = if link[:join].is_a?(Symbol)
                     "LEFT OUTER JOIN #{link[:join]} #{name.to_s.pluralize} ON #{column} = #{scope.table_name}.#{link[:column]}"
                   else
                     "LEFT OUTER JOIN #{link[:join][:table]} #{name.to_s.pluralize} ON #{link[:join][:condition]}"
                   end

            scope = scope.joins(join).select(link[:join][:select])
          end

          scope
        end

        def association_links_selects(select)
          self.association_links ||= {}

          association_links
            .slice(*cleaned_selects(select))
            .map do |name, link|
            path_name = link[:path] ? link[:path][:api] : name
            title = link[:title] ? link[:title].call : "#{name}.name"
            column = link[:column] ? link[:column].call : "#{name}.id"

            href = link[:href] ? link[:href].call : "format('#{api_v3_paths.send(path_name, '%s')}', #{column})"

            <<-SQL
             '#{name}', CASE
                        WHEN #{column} IS NOT NULL
                        THEN
                        json_build_object('href', #{href},
                                          'title', #{title})
                        ELSE
                        json_build_object('href', NULL,
                                          'title', NULL)
                        END
            SQL
          end
            .join(', ')
        end

        def link(name, column: nil, path: nil, title: nil, href: nil, join: nil)
          self.links ||= {}

          links[name] = { column: column,
                          path: path,
                          title: title,
                          join: join,
                          href: href }
        end

        def links_selects(select)
          self.links ||= {}

          links
            .slice(*cleaned_selects(select))
            .map do |name, link|
            path_name = link[:path] ? link[:path][:api] : name
            title = link[:title] ? link[:title].call : "#{name}.name"
            column = link[:column] ? link[:column].call : name

            href = link[:href] ? link[:href].call : "format('#{api_v3_paths.send(path_name, '%s')}', #{column})"

            link_attributes = ["'href'", href]

            if title
              link_attributes += ["'title'", title]
            end

            <<-SQL
             '#{name}', json_build_object(#{link_attributes.join(', ')})
            SQL
          end
            .join(', ')
        end

        def combined_links_selects(select)
          links_selects(select) +
            association_links_selects(select)

        end

        def select_sql(_replace_map, select)
          <<~SELECT
            json_build_object(
              #{properties_sql(select)},
              '_links',
                json_build_object(#{combined_links_selects(select)})
            )
          SELECT
        end

        private

        def cleaned_selects(select)
          # TODO: throw error on non supported select
          select
            .symbolize_keys
            .select { |_, v| v.empty? }
            .keys
        end
      end
    end
  end
end
