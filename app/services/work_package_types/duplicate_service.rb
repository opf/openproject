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

        result.result.insert_at(source.position + 1)

        unless source.variant?
          project_failure = copy_project_assignments(result.result)
          if project_failure
            result = project_failure
            raise ActiveRecord::Rollback
          end
        end

        aspect_failure = copy_configuration(result.result)
        if aspect_failure
          result = aspect_failure
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
        .call(core_attributes)
    end

    def core_attributes
      attributes = { name: duplicated_name, parent_id: source.parent_id }
      return attributes if source.variant?

      attributes.merge(
        color_id: source.color_id,
        is_milestone: source.is_milestone,
        is_in_roadmap: source.is_in_roadmap
      )
    end

    # Reached for roots only — a variant's copy starts with no projects, since a project enables
    # the family and resolves the variant separately. The copy is its own family, so no project
    # can be using it yet and Projects::Types::AddService always has a free slot to fill.
    def copy_project_assignments(copy)
      source.projects.find_each do |project|
        result = ::Projects::Types::AddService.new(user:, model: project).call(type: copy)
        return result if result.failure?
      end

      nil
    end

    def copy_configuration(copy)
      CopyConfiguration::SERVICES.each_pair do |aspect, service_class|
        aspect_result =
          if (linked_source = source.source_for(aspect))
            SwitchToLinkedModeService.new(type: copy, aspect:).call(source: linked_source)
          else
            service_class.new(type: copy, user:).call(source:)
          end

        return aspect_result if aspect_result.failure?
      end

      nil
    end

    # Name of a variant must stay unique per root type
    def duplicated_name
      base = I18n.t("types.index.duplicate_name", name: source.own_name)
      taken = Type.where(parent_id: source.parent_id).pluck(:name).map(&:downcase)

      return base unless taken.include?(base.downcase)

      counter = 2
      counter += 1 while taken.include?("#{base} (#{counter})".downcase)
      "#{base} (#{counter})"
    end
  end
end
