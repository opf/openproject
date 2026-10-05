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

module FieldRules
  class SchemeService
    class << self
      def create(params) = save(FieldRuleScheme.new, params)
      def update(scheme, params) = save(scheme, params)

      def clone(scheme)
        copy = FieldRuleScheme.new(name: clone_name(scheme), description: scheme.description, active: scheme.active)
        scheme.items.each { |item| copy.items.build(type_id: item.type_id, rule_set_id: item.rule_set_id) }
        copy.save ? ok(copy) : fail_with(copy)
      rescue ActiveRecord::RecordNotUnique
        copy.errors.add(:base, :conflict)
        fail_with(copy)
      end

      def activate(scheme) = toggle(scheme, true)
      def deactivate(scheme) = toggle(scheme, false)

      def assign(project, scheme)
        attempts = 0
        begin
          ProjectFieldRuleScheme.transaction(requires_new: true) do
            record = ProjectFieldRuleScheme.find_or_initialize_by(project_id: project.id)
            record.scheme = scheme
            record.save ? ok(record) : fail_with(record)
          end
        rescue ActiveRecord::RecordNotUnique
          retry if (attempts += 1) < 2
          ServiceResult.failure(errors: ActiveModel::Errors.new(ProjectFieldRuleScheme.new).tap { _1.add(:base, :conflict) })
        end
      end

      def unassign(project)
        ProjectFieldRuleScheme.where(project_id: project.id).destroy_all
        Resolver.reset_cache
        ServiceResult.success
      end

      def impact(scheme)
        { project_count: ProjectFieldRuleScheme.where(scheme_id: scheme.id).count,
          type_ids: scheme.items.map(&:type_id) }
      end

      private

      def toggle(scheme, active)
        scheme.update(active:) ? ok(scheme) : fail_with(scheme)
      end

      def clone_name(scheme)
        base = "#{scheme.name} - Custom"
        candidates = [base] + (2..).lazy.map { |n| "#{base} #{n}" }
        candidates.find { |name| !FieldRuleScheme.exists?(name:) }
      end

      def save(scheme, params)
        type_ids = params[:items]&.map { |item| item[:type_id].to_i }
        if type_ids && type_ids.uniq.size != type_ids.size
          scheme.errors.add(:items, :duplicate_types)
          return fail_with(scheme)
        end

        persist(scheme, params)
      rescue ActiveRecord::RecordNotUnique
        scheme.errors.add(:base, :conflict)
        fail_with(scheme)
      end

      def persist(scheme, params)
        result = nil
        FieldRuleScheme.transaction(requires_new: true) do
          scheme.lock! if scheme.persisted?
          scheme.assign_attributes(params.slice(:name, :description))
          sync_items(scheme, params[:items]) if params.key?(:items)
          result = scheme.save ? ok(scheme) : fail_with(scheme)
          raise ActiveRecord::Rollback if result.failure?
        end
        result
      end

      def sync_items(scheme, items)
        wanted = items.index_by { |item| item[:type_id].to_i }
        scheme.items.each { |item| item.mark_for_destruction unless wanted.key?(item.type_id) }
        wanted.each do |type_id, attrs|
          item = scheme.items.find { |existing| existing.type_id == type_id } || scheme.items.build(type_id:)
          item.rule_set_id = attrs[:rule_set_id].to_i
        end
      end

      def ok(result) = ServiceResult.success(result:)
      def fail_with(model) = ServiceResult.failure(result: model, errors: model.errors)
    end
  end
end
