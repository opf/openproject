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
  class SchemeService
    MAX_ITEMS = 500

    class << self
      def create(params) = save(TypeScheme.new, params)
      def update(scheme, params) = save(scheme, params)

      def clone(scheme)
        copy = TypeScheme.new(name: clone_name(scheme), description: scheme.description, active: scheme.active)
        scheme.items.each { |i| copy.items.build(type_id: i.type_id, position: i.position, is_default: i.is_default) }
        copy.save ? ok(copy) : fail_with(copy)
      end

      def deactivate(scheme)
        scheme.update(active: false, is_default: false) ? ok(scheme) : fail_with(scheme)
      end

      def activate(scheme)
        scheme.update(active: true) ? ok(scheme) : fail_with(scheme)
      end

      def destroy(scheme)
        names = scheme.projects.order(:name).pluck(:name)
        if names.any?
          scheme.errors.add(:project_assignments, :assigned_to_projects, projects: names.join(", "))
          return fail_with(scheme)
        end

        scheme.destroy ? ok(scheme) : fail_with(scheme)
      end

      def assign(project, scheme)
        attempts = 0
        begin
          ProjectTypeScheme.transaction(requires_new: true) do
            record = ProjectTypeScheme.find_or_initialize_by(project_id: project.id)
            record.scheme = scheme
            record.save ? ok(record) : fail_with(record)
          end
        rescue ActiveRecord::RecordNotUnique
          retry if (attempts += 1) < 2
          raise
        end
      end

      def unassign(project)
        ProjectTypeScheme.where(project_id: project.id).destroy_all
        ServiceResult.success
      end

      def impact(scheme, removed_type_ids: [])
        project_ids = scheme.project_assignments.pluck(:project_id)
        counts = WorkPackage.where(project_id: project_ids, type_id: removed_type_ids).group(:type_id).count
        { project_count: project_ids.size, work_package_counts: counts }
      end

      private

      def clone_name(scheme)
        base = "#{scheme.name} - Custom"
        candidates = [base] + (2..).lazy.map { |n| "#{base} #{n}" }
        candidates.find { |name| !TypeScheme.exists?(name:) }
      end

      def duplicate_types?(items)
        ids = items&.map { |i| i[:type_id].to_i }
        ids && ids.uniq.size != ids.size
      end

      def save(scheme, params)
        if duplicate_types?(params[:items])
          scheme.errors.add(:items, :duplicate_types)
          return fail_with(scheme)
        end
        if params[:items] && params[:items].size > MAX_ITEMS
          scheme.errors.add(:items, :too_many, count: MAX_ITEMS)
          return fail_with(scheme)
        end

        result = nil
        TypeScheme.transaction(requires_new: true) do
          scheme.lock! if scheme.persisted?
          scheme.assign_attributes(params.slice(:name, :description, :is_default))
          prepare_items(scheme, params[:items]) if params.key?(:items)
          result = scheme.save ? ok(scheme) : fail_with(scheme)
          raise ActiveRecord::Rollback if result.failure?
        end
        result
      end

      # Persisted items are removed / un-defaulted up front so the unique indexes
      # (one default per scheme, one row per type) cannot collide while saving.
      # The surrounding transaction is rolled back if validation fails.
      def prepare_items(scheme, items)
        wanted = items.index_by { |i| i[:type_id].to_i }
        if scheme.persisted?
          scheme.items.where.not(type_id: wanted.keys).destroy_all
          scheme.items.update_all(is_default: false)
          scheme.items.reset
        end
        wanted.each do |type_id, attrs|
          item = scheme.items.find { |i| i.type_id == type_id } || scheme.items.build(type_id:)
          item.assign_attributes(position: attrs[:position] || 0, is_default: attrs[:is_default] || false)
        end
      end

      def ok(result) = ServiceResult.success(result:)
      def fail_with(model) = ServiceResult.failure(result: model, errors: model.errors)
    end
  end
end
