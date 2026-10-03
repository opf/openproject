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
        scheme = DefaultScheme.ensure!
        assign_projects(scheme) if @mode == "auto"
      end
      plan
    end

    private

    def types
      @types ||= Type.order(:position, :id).to_a
    end

    def unassigned_projects
      Project.where(<<~SQL.squish).order(:name)
        NOT EXISTS (SELECT 1 FROM project_type_schemes WHERE project_type_schemes.project_id = projects.id)
      SQL
    end

    def build_plan
      Plan.new(scheme_name: DefaultScheme.current&.name || DefaultScheme::NAME,
               type_names: types.map(&:name),
               default_type_name: DefaultScheme.task_type(types)&.name,
               project_names: @mode == "manual" ? [] : unassigned_projects.pluck(:name))
    end

    def assign_projects(scheme)
      now = Time.zone.now
      sql = ProjectTypeScheme.sanitize_sql_array([<<~SQL.squish, scheme.id, now, now])
        INSERT INTO project_type_schemes (project_id, scheme_id, created_at, updated_at)
        SELECT projects.id, ?, ?, ? FROM projects
        WHERE NOT EXISTS (SELECT 1 FROM project_type_schemes WHERE project_type_schemes.project_id = projects.id)
        ON CONFLICT (project_id) DO NOTHING
      SQL
      ProjectTypeScheme.connection.execute(sql)
      Resolver.reset_cache
    end
  end
end
