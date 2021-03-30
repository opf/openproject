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
    module Sql
      module Hal
        extend ActiveSupport::Concern

        included do
          extend ::API::V3::Utilities::PathHelper

          class_attribute :embed_map,
                          default: {}
          class_attribute :properties,
                          default: {}
          class_attribute :links,
                          default: {}
          class_attribute :embeddeds,
                          default: {}
        end

        class_methods do
          def properties_sql(select, walker_results)
            selected_properties(select)
              .map do |name, options|
              representation = if options[:representation]
                                 options[:representation].call(walker_results)
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
            properties[name] = { column: column, render_if: render_if, representation: representation }
          end

          def joins(select, scope)
            selected_links(select)
              .select { |_, link| link[:join] }
              .map do |name, link|
              join = "LEFT OUTER JOIN #{link[:join][:table]} #{name.to_s.pluralize} ON #{link[:join][:condition]}"

              scope = scope.joins(join).select(link[:join][:select])
            end

            scope
          end

          def link(name, column: nil, path: nil, title: nil, href: nil, join: nil, render_if: nil, **additional_properties)
            links[name] = { column: column,
                            path: path,
                            title: title,
                            join: join,
                            href: href,
                            render_if: render_if,
                            additional_properties: additional_properties }
          end

          def links_selects(select, walker_result)
            selected_links(select)
              .map do |name, link|
              path_name = link[:path] ? link[:path][:api] : name
              title = link[:title] ? link[:title].call : "#{name}.name"
              column = link[:column] ? link[:column].call : name

              href = link[:href] ? link[:href].call(walker_result) : "format('#{api_v3_paths.send(path_name, '%s')}', #{column})"

              link_attributes = ["'href'", href]

              if title
                link_attributes += ["'title'", title]
              end

              (link[:additional_properties] || {}).each do |key, value|
                link_attributes += ["'#{key}'", value]
              end

              if link[:render_if]
                <<-SQL
                 '#{name}',
                 CASE WHEN #{link[:render_if].call(walker_result)} THEN
                   json_build_object(#{link_attributes.join(', ')})
                 ELSE
                   NULL
                 END
                SQL
              else
                <<-SQL
                 '#{name}', json_build_object(#{link_attributes.join(', ')})
                SQL
              end
            end
              .join(', ')
          end

          def embedded(name,
                       representation: nil)
            embeddeds[name] = { representation: representation }
          end

          def embedded_selects(_selects, walker_results)
            # TODO: This does not yet support signaling
            embeddeds
              .map do |name, link|

              representation = if link[:representation]
                                 link[:representation].call(walker_results)
                               else
                                 link[:column]
                               end

              <<-SQL
               '#{name}', #{representation}
              SQL
            end
              .join(', ')
          end

          def select_sql(select, walker_result)
            <<~SELECT
              json_strip_nulls(json_build_object(
                #{[properties_sql(select, walker_result),
                   select_links(select, walker_result),
                   select_embedded(select, walker_result)].compact.join(', ')}
              ))
            SELECT
          end

          def ctes(_walker_result)
            {}
          end

          def to_sql(walker_result)
            ctes = walker_result.ctes.map do |key, sql|
              <<~SQL
                #{key} AS (
                  #{sql}
                )
              SQL
            end

            ctes_sql = ctes.any? ? "WITH #{ctes.join(', ')}" : ""

            <<~SQL
              #{ctes_sql}

              SELECT
                #{walker_result.selects} AS json
              FROM
                #{select_from(walker_result)}
            SQL
          end

          private

          def select_embedded(select, walker_result)
            embedded = embedded_selects(select, walker_result)

            if embedded.present?
              <<~SQL
                '_embedded', json_strip_nulls(json_build_object(
                  #{embedded_selects(select, walker_result)}
                ))
              SQL
            end
          end

          def select_links(select, walker_result)
            <<~SELECT
              '_links', json_strip_nulls(json_build_object(
                #{links_selects(select, walker_result)}
              ))
            SELECT
          end

          def select_from(walker_result)
            "(#{walker_result.scope.to_sql}) element"
          end

          def selected_links(select)
            selected(select, links)
          end

          def selected_properties(select)
            selected(select, properties)
          end

          def selected(select, list)
            selects = cleaned_selects(select)

            ensure_valid_selects(selects)

            if selects.include?(:*)
              list
            else
              list.slice(*selects)
            end
          end

          def cleaned_selects(select)
            select
              .symbolize_keys
              .select { |_, v| v.empty? }
              .keys
          end

          def ensure_valid_selects(requested)
            supported = links.keys + properties.keys + [:*]
            invalid = requested - supported

            raise API::Errors::InvalidSignal.new(invalid, supported, :select) if invalid.any?
          end
        end
      end
    end
  end
end
