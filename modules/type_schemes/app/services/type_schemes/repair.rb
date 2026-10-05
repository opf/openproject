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
  class Repair
    LOCK_KEY = 7_204_117
    BATCH_SIZE = 1000

    Report = Struct.new(:dry_run, :findings, keyword_init: true) do
      def changed? = findings.any?
    end

    def self.call(dry_run: true) = new(dry_run:).call

    def initialize(dry_run:)
      @dry_run = dry_run
      @findings = []
    end

    def call
      TypeScheme.transaction do
        TypeScheme.connection.execute("SELECT pg_advisory_xact_lock(#{LOCK_KEY})") unless @dry_run
        restore_default_scheme
        add_missing_types_to_default_scheme
        restore_default_items
        assign_unassigned_projects
      end
      Resolver.reset_cache
      Report.new(dry_run: @dry_run, findings: @findings)
    end

    private

    def restore_default_scheme
      return if DefaultScheme.current

      inactive = TypeScheme.find_by(is_default: true)
      if inactive
        record("Re-activate default scheme '#{inactive.name}'")
        inactive.update_columns(active: true, updated_at: Time.current) unless @dry_run
      elsif Type.exists?
        record("Create '#{DefaultScheme::NAME}' from all types")
        DefaultScheme.ensure! unless @dry_run
      end
    end

    def add_missing_types_to_default_scheme
      scheme = DefaultScheme.current
      return unless scheme

      missing = Type.where.not(id: scheme.items.map(&:type_id)).order(:position, :id).to_a
      return if missing.empty?

      record("Add #{missing.size} type(s) missing from '#{scheme.name}': #{missing.map(&:name).join(', ')}")
      return if @dry_run

      last_position = scheme.items.map(&:position).max.to_i
      rows = missing.each_with_index.map do |type, index|
        { scheme_id: scheme.id, type_id: type.id, position: last_position + index + 1, is_default: false }
      end
      TypeSchemeItem.insert_all(rows, unique_by: %i[scheme_id type_id])
    end

    def restore_default_items
      TypeScheme.active.includes(items: :type).find_each do |scheme|
        next if scheme.items.any?(&:is_default)
        next if scheme.items.empty? && scheme.is_default && @dry_run

        item = promotable_item(scheme)
        if item
          record("Make '#{item.type.name}' the default type of '#{scheme.name}'")
          item.update_columns(is_default: true, updated_at: Time.current) unless @dry_run
        else
          record("Scheme '#{scheme.name}' is active but has no types; an administrator has to fix it")
        end
      end
    end

    def promotable_item(scheme)
      type = DefaultScheme.task_type(scheme.items.map(&:type))
      scheme.items.find { |item| item.type_id == type&.id }
    end

    def assign_unassigned_projects
      unassigned = Project.where.not(id: ProjectTypeScheme.select(:project_id))
      stale = ProjectTypeScheme.where(scheme_id: TypeScheme.where(active: false).select(:id))
      record("Assign the default scheme to #{unassigned.count} project(s) without a scheme") if unassigned.exists?
      record("Move #{stale.count} project(s) from an inactive scheme to the default scheme") if stale.exists?

      default = DefaultScheme.current
      return if @dry_run || default.nil?

      unassigned.in_batches(of: BATCH_SIZE) do |batch|
        rows = batch.pluck(:id).map { |project_id| { project_id:, scheme_id: default.id } }
        ProjectTypeScheme.insert_all(rows, unique_by: :project_id)
      end
      stale.update_all(scheme_id: default.id, updated_at: Time.current)
    end

    def record(message)
      @findings << message
    end
  end
end
