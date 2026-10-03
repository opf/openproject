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

# frozen_string_literal: true

module TypeSchemes
  class DefaultMigration
    SCHEME_NAME = "Default Scheme"
    MODES = %w[dry_run auto manual].freeze

    Plan = Struct.new(:scheme_name, :type_names, :default_type_name, :project_names, keyword_init: true)

    def self.call(mode: "dry_run") = new(mode:).call

    def initialize(mode:)
      raise ArgumentError, "mode must be one of #{MODES.join(', ')}" unless MODES.include?(mode.to_s)

      @mode = mode.to_s
    end

    def call
      plan = build_plan
      return plan if @mode == "dry_run" || plan.type_names.empty?

      TypeScheme.transaction do
        scheme = find_or_create_scheme!
        assign_projects(scheme) if @mode == "auto"
      end
      plan
    end

    private

    def types
      @types ||= Type.where(id: ProjectType.select(:type_id)).order(:position, :id).to_a
    end

    def unassigned_projects
      Project.where.not(id: ProjectTypeScheme.select(:project_id)).order(:name)
    end

    def build_plan
      Plan.new(scheme_name: SCHEME_NAME,
               type_names: types.map(&:name),
               default_type_name: types.first&.name,
               project_names: @mode == "manual" ? [] : unassigned_projects.pluck(:name))
    end

    def find_or_create_scheme!
      TypeScheme.find_by(name: SCHEME_NAME) || create_scheme!
    end

    def create_scheme!
      items = types.each_with_index.map do |type, index|
        { type_id: type.id, position: index + 1, is_default: index.zero? }
      end
      make_default = @mode == "auto" && !TypeScheme.exists?(is_default: true)
      result = SchemeService.create(name: SCHEME_NAME, items:, is_default: make_default)
      raise ActiveRecord::RecordInvalid, result.result if result.failure?

      result.result
    end

    def assign_projects(scheme)
      unassigned_projects.find_each { |project| SchemeService.assign(project, scheme) }
    end
  end
end
