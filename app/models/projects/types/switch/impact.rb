# frozen_string_literal: true

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

module Projects
  module Types
    # A namespace, not a form object: what a switch is gets decided by SwitchVariantContract
    # and carried out by SwitchVariantService.
    module Switch
      # What switching a project from one family member to another will do.
      #
      # Type#attribute_groups and Type#statuses already resolve through the
      # effective configuration source, so a variant that borrows its parent's
      # configuration compares as its parent with no extra plumbing here.
      class Impact
        Field = Data.define(:key, :label, :kind)

        def initialize(project:, source:, target:)
          @project = project
          @source = source
          @target = target
        end

        def work_package_count
          @work_package_count ||= work_packages.count
        end

        def hidden_fields
          @hidden_fields ||= fields_of(source) - fields_of(target)
        end

        def new_fields
          @new_fields ||= fields_of(target) - fields_of(source)
        end

        def hidden_custom_field_counts
          @hidden_custom_field_counts ||= count_custom_values(hidden_custom_field_ids)
        end

        # The preview holds Fields, not custom field ids, so the derivation stays
        # here. A field that is becoming available has no count by construction:
        # only hidden fields are counted.
        def value_count(field)
          hidden_custom_field_counts[custom_field_id(field)]
        end

        # Work packages whose status the target's workflow cannot move them out of. Assignable
        # statuses come from the effective type's workflow and always include the current one,
        # so a status with no transition leaves a work package with itself as its only choice:
        # frozen, with no error to explain it. This is why the report gives these top billing.
        def missing_statuses
          @missing_statuses ||= begin
            counts = work_packages
                       .where.not(status_id: target.statuses.select(:id))
                       .group(:status_id)
                       .count

            ::Status.where(id: counts.keys).index_with { counts[it.id] }
          end
        end

        def anything_affected?
          hidden_fields.any? || new_fields.any? || missing_statuses.any?
        end

        # Public so the report can link to the work packages behind its counters.
        attr_reader :project, :source, :target

        private

        # Scoped on the type, not the variant: a work package stores its type whichever variant
        # the project resolves to, so scoping on the variant would match nothing and quietly
        # report an impact of zero on every count drawn from here.
        def work_packages
          @work_packages ||= ::WorkPackage.where(project:, type_id: source.type_id)
        end

        # members, not active_members(project): switching enables the target's
        # custom fields on the project, so a project-scoped view would
        # under-report exactly the fields that are about to appear.
        def fields_of(type)
          type.attribute_groups.flat_map { group_fields(it) }
        end

        def group_fields(group)
          if group.is_a?(::Type::QueryGroup)
            [Field.new(key: "table:#{group.translated_key}", label: group.translated_key, kind: :table)]
          else
            group.members.map { field_for(it) }
          end
        end

        def field_for(key)
          kind = ::CustomField.custom_field_attribute?(key) ? :custom_field : :builtin

          Field.new(key:, label: attribute_labels[key], kind:)
        end

        # merge_date: true because AttributeGroup#members filters against
        # work_package_attributes, where start and due date collapse into one
        # "date" member that the unmerged map does not carry.
        def attribute_labels
          @attribute_labels ||= ::TypeVariant.translated_work_package_form_attributes(merge_date: true)
        end

        def hidden_custom_field_ids
          hidden_fields.filter_map { custom_field_id(it) }
        end

        def custom_field_id(field)
          field.key.delete_prefix("custom_field_").to_i if field.kind == :custom_field
        end

        # A subquery rather than plucked ids, so a project with tens of thousands
        # of work packages does not marshal them into the query.
        def count_custom_values(custom_field_ids)
          return {} if custom_field_ids.empty?

          ::CustomValue
            .where(customized_type: "WorkPackage", customized_id: work_packages.select(:id))
            .where(custom_field_id: custom_field_ids)
            .where.not(value: [nil, ""])
            .group(:custom_field_id)
            .count
        end
      end
    end
  end
end
