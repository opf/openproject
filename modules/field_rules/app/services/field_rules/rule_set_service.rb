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
  class RuleSetService
    RULE_ATTRIBUTES = %i[hidden required read_only enforce_on_update default_value position].freeze

    class << self
      def create(params) = save(FieldRuleSet.new, params)
      def update(rule_set, params) = save(rule_set, params)

      def clone(rule_set)
        copy = FieldRuleSet.new(name: clone_name(rule_set), description: rule_set.description, active: rule_set.active)
        rule_set.rules.each do |rule|
          copy.rules.build(rule.attributes.slice("field_key", *RULE_ATTRIBUTES.map(&:to_s)))
        end
        copy.save ? ok(copy) : fail_with(copy)
      end

      def activate(rule_set) = toggle(rule_set, true)
      def deactivate(rule_set) = toggle(rule_set, false)

      def impact(rule_set)
        scheme_ids = FieldRuleSchemeItem.where(rule_set_id: rule_set.id).select(:scheme_id)
        { scheme_count: FieldRuleSchemeItem.where(rule_set_id: rule_set.id).distinct.count(:scheme_id),
          project_count: ProjectFieldRuleScheme.where(scheme_id: scheme_ids).count,
          work_package_count: affected_work_packages(rule_set) }
      end

      private

      def affected_work_packages(rule_set)
        WorkPackage
          .joins("INNER JOIN project_field_rule_schemes pfrs ON pfrs.project_id = work_packages.project_id")
          .joins("INNER JOIN field_rule_scheme_items frsi ON frsi.scheme_id = pfrs.scheme_id " \
                 "AND frsi.type_id = work_packages.type_id")
          .where(frsi: { rule_set_id: rule_set.id })
          .count
      end

      def toggle(rule_set, active)
        rule_set.update(active:) ? ok(rule_set) : fail_with(rule_set)
      end

      def clone_name(rule_set)
        base = "#{rule_set.name} - Custom"
        candidates = [base] + (2..).lazy.map { |n| "#{base} #{n}" }
        candidates.find { |name| !FieldRuleSet.exists?(name:) }
      end

      def save(rule_set, params)
        rules = params[:rules]
        keys = rules&.map { |rule| rule[:field_key].to_s }
        if keys && keys.uniq.size != keys.size
          rule_set.errors.add(:rules, :duplicate_fields)
          return fail_with(rule_set)
        end

        persist(rule_set, params)
      rescue ActiveRecord::RecordNotUnique
        rule_set.errors.add(:base, :conflict)
        fail_with(rule_set)
      end

      def persist(rule_set, params)
        result = nil
        FieldRuleSet.transaction(requires_new: true) do
          rule_set.lock! if rule_set.persisted?
          rule_set.assign_attributes(params.slice(:name, :description))
          sync_rules(rule_set, params[:rules]) if params.key?(:rules)
          result = rule_set.save ? ok(rule_set) : fail_with(rule_set)
          raise ActiveRecord::Rollback if result.failure?
        end
        result
      end

      def sync_rules(rule_set, rules)
        wanted = rules.index_by { |rule| rule[:field_key].to_s }
        rule_set.rules.each { |rule| rule.mark_for_destruction unless wanted.key?(rule.field_key) }
        wanted.each_value.with_index do |attrs, index|
          rule = rule_set.rules.find { |existing| existing.field_key == attrs[:field_key].to_s } ||
                 rule_set.rules.build(field_key: attrs[:field_key].to_s)
          rule.assign_attributes(rule_attributes(attrs, index))
        end
      end

      def rule_attributes(attrs, index)
        attrs.slice(*RULE_ATTRIBUTES).tap { |hash| hash[:position] = hash.fetch(:position, index) }
      end

      def ok(result) = ServiceResult.success(result:)
      def fail_with(model) = ServiceResult.failure(result: model, errors: model.errors)
    end
  end
end
