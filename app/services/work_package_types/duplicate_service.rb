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

module WorkPackageTypes
  # Duplicates a type: a new type with the same core settings, project assignments and
  # base-variant configuration (including linked aspects). Named variants are not copied —
  # a project that resolved the source family to a named variant has to be pointed at one
  # on the copy explicitly.
  class DuplicateService
    def initialize(type:, user:)
      @source = type
      @user = user
    end

    def call
      result = nil

      Type.transaction do
        result = create_copy
        raise ActiveRecord::Rollback if result.failure?

        copy = result.result
        copy.insert_at(source.position + 1)

        failure = copy_configuration(copy) || copy_project_assignments(copy)
        if failure
          result = failure
          raise ActiveRecord::Rollback
        end
      end

      result
    end

    private

    attr_reader :source, :user

    def create_copy
      WorkPackageTypes::CreateService
        .new(user:)
        .call(
          name: duplicated_name,
          color_id: source.color_id,
          is_milestone: source.is_milestone,
          is_in_roadmap: source.is_in_roadmap,
          allow_project_variants: source.allow_project_variants
        )
    end

    # The copy has only a base variant — #copy_configuration writes that one — so that is what
    # every project inheriting the assignment applies. It has to run after the configuration is
    # in place: adding a variant to a project activates the custom fields that variant shows, and
    # before the form configuration is copied it shows none.
    def copy_project_assignments(copy)
      source.projects.find_each do |project|
        result = ::Projects::Types::AddService.new(user:, model: project).call(variant: copy.default_variant)
        return result if result.failure?
      end

      nil
    end

    def copy_configuration(copy)
      source_variant = source.default_variant
      copy_variant = copy.default_variant

      CopyConfiguration::SERVICES.each_pair do |aspect, service_class|
        aspect_result =
          if (linked_source = source_variant.source_for(aspect))
            SwitchToLinkedModeService.new(variant: copy_variant, aspect:).call(source: linked_source)
          else
            service_class.new(variant: copy_variant, user:).call(source: source_variant)
          end

        return aspect_result if aspect_result.failure?
      end

      nil
    end

    def duplicated_name
      base = I18n.t("types.index.duplicate_name", name: source.name)
      taken = Type.pluck(:name).map(&:downcase)

      return base unless taken.include?(base.downcase)

      counter = 2
      counter += 1 while taken.include?("#{base} (#{counter})".downcase)
      "#{base} (#{counter})"
    end
  end
end
