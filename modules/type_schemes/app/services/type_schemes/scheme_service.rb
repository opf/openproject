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
        TypeScheme.transaction(requires_new: true) do
          scheme.lock!
          if scheme.is_default
            scheme.errors.add(:active, :default_scheme_required)
            raise ActiveRecord::Rollback
          end

          default = DefaultScheme.ensure!
          scheme.project_assignments.update_all(scheme_id: default.id) if default
          scheme.update!(active: false)
          Resolver.reset_cache
        end
        scheme.errors.any? ? fail_with(scheme) : ok(scheme)
      end

      def activate(scheme)
        scheme.update(active: true) ? ok(scheme) : fail_with(scheme)
      end

      def assign(project, scheme)
        attempts = 0
        begin
          ProjectTypeScheme.transaction(requires_new: true) do
            record = ProjectTypeScheme.find_or_initialize_by(project:)
            record.scheme = scheme
            record.save ? ok(record) : fail_with(record)
          end
        rescue ActiveRecord::RecordNotUnique
          retry if (attempts += 1) < 2
          raise
        end
      end

      def assign_default(project)
        default = DefaultScheme.ensure!
        return ServiceResult.success unless default

        assign(project, default)
      end

      def impact(scheme, removed_type_ids: [])
        assignments = scheme.project_assignments
        counts = if removed_type_ids.empty?
                   {}
                 else
                   WorkPackage.where(type_id: removed_type_ids, project_id: assignments.select(:project_id))
                              .group(:type_id).count
                 end
        { project_count: assignments.count, work_package_counts: counts }
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

        persist(scheme, params)
      rescue ActiveRecord::RecordNotUnique
        scheme.errors.add(:base, :conflict)
        fail_with(scheme)
      end

      def persist(scheme, params)
        result = nil
        TypeScheme.transaction(requires_new: true) do
          scheme.lock! if scheme.persisted?
          scheme.assign_attributes(params.slice(:name, :description))
          unless apply_default_flag(scheme, params)
            result = fail_with(scheme)
            raise ActiveRecord::Rollback
          end
          prepare_items(scheme, params[:items]) if params.key?(:items)
          result = scheme.save ? ok(scheme) : fail_with(scheme)
          raise ActiveRecord::Rollback if result.failure?
        end
        result
      end

      def apply_default_flag(scheme, params)
        return true unless params.key?(:is_default)

        wanted = params[:is_default] ? true : false
        if wanted && !scheme.is_default
          TypeScheme.where(is_default: true).update_all(is_default: false)
          scheme.is_default = true
        elsif !wanted && scheme.is_default
          scheme.errors.add(:is_default, :default_scheme_required)
          return false
        end
        true
      end

      # Persisted items are removed / un-defaulted up front so the unique indexes
      # (one default per scheme, one row per type) cannot collide while saving.
      # The surrounding transaction is rolled back if validation fails.
      def prepare_items(scheme, items)
        wanted = items.index_by { |i| i[:type_id].to_i }
        if scheme.persisted?
          scheme.items.where.not(type_id: wanted.keys).delete_all
          scheme.items.update_all(is_default: false)
          scheme.items.reset
          Resolver.reset_cache
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
