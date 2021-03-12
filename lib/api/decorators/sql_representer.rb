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
          selected_properties(select)
            .map do |name, options|
            representation = if options[:representation]
                               options[:representation].call
                             else
                               options[:column]
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

        def joins(select, scope)
          self.links ||= {}

          selected_links(select)
            .select { |_, link| link[:join] }
            .map do |name, link|
            join = "LEFT OUTER JOIN #{link[:join][:table]} #{name.to_s.pluralize} ON #{link[:join][:condition]}"

            scope = scope.joins(join).select(link[:join][:select])
          end

          scope
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
          selected_links(select)
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

        def select_sql(_replace_map, select)
          <<~SELECT
            json_build_object(
              #{properties_sql(select)},
              '_links',
                json_build_object(#{links_selects(select)})
            )
          SELECT
        end

        private

        def selected_links(select)
          (links || {})
            .slice(*cleaned_selects(select))
        end

        def selected_properties(select)
          (properties || {})
            .slice(*cleaned_selects(select))
        end

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
