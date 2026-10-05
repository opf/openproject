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
    HEX_COLOR = /\A#?([0-9a-fA-F]{6})\z/

    class << self
      def create(params) = save(TypeScheme.new, params)
      def update(scheme, params) = save(scheme, params)

      def clone(scheme)
        copy = TypeScheme.new(name: clone_name(scheme), description: scheme.description, active: scheme.active)
        scheme.items.each do |item|
          copy.items.build(type_id: item.type_id, position: item.position,
                           is_default: item.is_default, color_id: item.color_id)
        end
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

          items = params[:items]
          if params[:new_type_names].present?
            created = TypeCreator.call(params[:new_type_names])
            if created.failure?
              created.errors.full_messages.each { |message| scheme.errors.add(:base, message) }
              result = fail_with(scheme)
              raise ActiveRecord::Rollback
            end
            items = merge_new_types(items || current_items(scheme), created.result)
          end

          if items
            if duplicate_types?(items)
              scheme.errors.add(:items, :duplicate_types)
              result = fail_with(scheme)
              raise ActiveRecord::Rollback
            end
            if items.size > MAX_ITEMS
              scheme.errors.add(:items, :too_many, count: MAX_ITEMS)
              result = fail_with(scheme)
              raise ActiveRecord::Rollback
            end
            prepare_items(scheme, items)
          end

          result = scheme.save ? ok(scheme) : fail_with(scheme)
          raise ActiveRecord::Rollback if result.failure?
        end
        result
      end

      def current_items(scheme)
        scheme.items.reject(&:marked_for_destruction?).map do |item|
          { type_id: item.type_id, position: item.position, is_default: item.is_default, color_id: item.color_id }
        end
      end

      # Appends the freshly created types as enabled items after the existing ones.
      # If none of the items is marked default, the first one becomes it so an
      # active scheme keeps exactly one default.
      def merge_new_types(items, types)
        merged = items.map { |item| item.dup }
        known = merged.map { |item| item[:type_id].to_i }
        position = merged.map { |item| item[:position].to_i }.max.to_i + 1

        types.each do |type|
          next if known.include?(type.id)

          merged << { type_id: type.id, position:, is_default: false }
          known << type.id
          position += 1
        end

        merged.first[:is_default] = true if merged.any? && merged.none? { |item| item[:is_default] }
        merged
      end

      # "custom" (or a hexcode with no explicit mode) resolves to a Color by its
      # hexcode, creating one on demand; otherwise an existing Color id is used.
      def resolve_color(params, id_key:, hex_key:, mode_key:)
        mode = params[mode_key].presence
        if mode == "custom" || (mode.nil? && params[hex_key].present?)
          color_id_for_hex(params[hex_key])
        else
          Color.where(id: params[id_key].presence).pick(:id)
        end
      end

      def color_id_for_hex(value)
        hex = normalize_hex(value)
        return if hex.nil?

        Color.where("LOWER(hexcode) = ?", hex).pick(:id) || create_color(hex)
      end

      def normalize_hex(value)
        match = HEX_COLOR.match(value.to_s.strip)
        "##{match[1].downcase}" if match
      end

      def create_color(hex)
        Color.create(name: hex, hexcode: hex).id
      rescue StandardError => e
        Rails.logger.error("[type_schemes] creating color #{hex} failed: #{e.class}: #{e.message}")
        nil
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
          item.color_id = resolve_color(attrs, id_key: :color_id, hex_key: :color_hex, mode_key: :color_mode)
          item.assign_attributes(position: attrs[:position] || 0, is_default: attrs[:is_default] || false)
        end
      end

      def ok(result) = ServiceResult.success(result:)
      def fail_with(model) = ServiceResult.failure(result: model, errors: model.errors)
    end
  end
end
