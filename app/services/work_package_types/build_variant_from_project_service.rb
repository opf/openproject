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
  # Turns a project's per-project custom field deactivations into a variant, so the narrowing a
  # project used to express by disabling single fields becomes part of the form configuration
  # instead.
  #
  # The variant inherits every aspect from the given type and excludes only the custom fields the
  # project has not enabled. A project that narrows nothing needs no variant, so the given type is
  # returned unchanged — callers can assign the result to the project either way.
  class BuildVariantFromProjectService < ::BaseServices::BaseCallable
    def initialize(user:, type:)
      super()
      @user = user
      @source = type
    end

    protected

    def perform(*)
      project = params[:project]

      elements = elements_to_exclude(project)
      return ServiceResult.success(result: source) if elements.empty?

      build_variant(project, elements)
    end

    private

    attr_reader :source, :user

    def build_variant(project, elements)
      result = nil

      Type.transaction do
        result = create_variant(project)
        raise ActiveRecord::Rollback if result.failure?

        variant = result.result
        link_aspects_to_source(variant)

        exclusion = exclude_elements(variant, elements)
        if exclusion.failure?
          result = exclusion
          raise ActiveRecord::Rollback
        end
      end

      result
    end

    def create_variant(project)
      # TODO: When FND-204 is fully implemented and we can create project specific variants, let's ensure that
      # we create a project specific variant here.
      CreateService
        .new(user:)
        .call(name: variant_name(project), parent_id: source.root_id)
    end

    # A variant is always a child of a root, so a variant built from another variant cannot nest
    # under it. The configuration links are what carry the relationship: pointing them at the
    # source variant makes its own exclusions accumulate with the ones added below.
    def link_aspects_to_source(variant)
      return unless source.variant?

      Type::ConfigurationLink::ASPECTS.each { |aspect| variant.link!(aspect, source:) }
    end

    def exclude_elements(variant, elements)
      ExcludedElements::AddService
        .new(user:, type: variant)
        .call(aspect: Type::ConfigurationLink::FORM_CONFIGURATION, elements:)
    end

    # `source.custom_fields` is the type-level set the form configuration puts on a work package,
    # already resolved through the source's own links and exclusions. Whatever of it the project
    # has not enabled is exactly what disabling single fields used to hide.
    def elements_to_exclude(project)
      active_ids = project.all_work_package_custom_fields.pluck(:id)

      source.custom_fields
            .reject { active_ids.include?(it.id) }
            .map(&:attribute_name)
    end

    # Name of a variant must stay unique per root type
    def variant_name(project)
      base = "#{source.own_name} - #{project.name}"
      taken = Type.where(parent_id: source.root_id).pluck(:name).map(&:downcase)

      return base unless taken.include?(base.downcase)

      counter = 2
      counter += 1 while taken.include?("#{base} (#{counter})".downcase)
      "#{base} (#{counter})"
    end
  end
end
