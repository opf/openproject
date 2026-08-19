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
    module CustomFields
      module Hierarchy
        class ItemsAPI < ::API::OpenProjectAPI
          include Dry::Monads[:result]

          helpers do
            def flatten_tree_hash(hash)
              flat_list = []
              queue = [hash.merge({ depth: -1 })]

              # From the service we get a hashed tree like this:
              # {:a => {:b => {:c1 => {:d1 => {}}, :c2 => {:d2 => {}}}, :b2 => {}}}
              #
              # We flatten it depth first to this result list:
              # [:a, :b, :c1, :d1, :c2, :d2, :b2]

              while queue.any?
                current = queue.shift
                depth = current[:depth]
                item, children = current.shift

                flat_list << HierarchicalItemAggregate.new(item:, depth:)

                queue.unshift(current) unless current.keys == [:depth]
                queue.unshift(children.merge({ depth: depth + 1 })) unless children.empty?
              end

              flat_list
            end

            def item_list(query)
              hierarchy_root = get_hierarchy_root(query)

              validation = GetItemsParameterContract.new(hierarchy_root:).call(params)
              handle_validation_errors(validation) if validation.failure?

              start_item = ::CustomField::Hierarchy::Item.find_by(id: validation[:parent]) || hierarchy_root
              depth = validation[:depth] || -1

              flat_tree(start_item, depth)
            end

            def flat_tree(item, depth)
              sub_tree = ::CustomFields::Hierarchy::HierarchicalItemService
                           .new
                           .hashed_subtree(item:, depth:)
                           .either(
                             ->(value) { value },
                             ->(error) do
                               msg = "#{I18n.t('api_v3.errors.code_500')} #{error}"
                               raise ::API::Errors::SafeInternalError.new(msg)
                             end
                           )

              flatten_tree_hash(sub_tree)
            end

            def get_hierarchy_root(query)
              items = query.results.where(custom_field: @custom_field)
              if items.count != 1
                msg = "corrupt data found, invalid number of hierarchy roots for custom field"
                raise ::API::Errors::SafeInternalError.new(msg)
              end

              items.first
            end

            def handle_validation_errors(validation)
              message = ""
              validation.errors(full: true).to_h.each_value do |value|
                message += "#{value.join(', ')}\n"
              end

              raise ::API::Errors::InvalidQuery.new(message.chomp)
            end
          end

          resource :items do
            after_validation do
              unless @custom_field.hierarchical_list?
                message = "Hierarchy items not available for custom fields of type #{@custom_field.field_format}."
                raise ::API::Errors::UnprocessableContent.new(message)
              end
            end

            get do
              query = ParamsToQueryService.new(::CustomField::Hierarchy::Item,
                                               current_user,
                                               query_class: ::Queries::CustomFields::Hierarchy::ItemQuery)
                                          .call(params)

              unless query.valid?
                message = I18n.t("api_v3.errors.missing_or_malformed_parameter", parameter: "filters")
                raise ::API::Errors::InvalidQuery.new(message)
              end

              self_link = api_v3_paths.custom_field_items(@custom_field.id, params[:parent], params[:depth])
              HierarchyItemCollectionRepresenter.new(item_list(query), self_link:, current_user:)
            end
          end
        end
      end
    end
  end
end
