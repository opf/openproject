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

require "set"

module Screens
  # The single source of truth for the effective layout of a (project, type, context). It merges
  # the screen configuration with the field rules (F02) and never raises into its callers: any
  # internal error falls back to the native layout.
  module Resolver
    CACHE_KEY = :screens_resolved
    CONTEXTS = %i[create edit view transition].freeze
    FALLBACKS = {
      create: %i[create],
      edit: %i[edit],
      view: %i[view edit],
      transition: %i[transition]
    }.freeze
    MAX_FOR_MANY = 500

    @raise_on_error = false

    class << self
      attr_accessor :raise_on_error
    end

    module_function

    def for(project, type, context)
      context = normalize_context(context)
      project_id = id_of(project)
      type_id = id_of(type)
      return native(:no_scheme, context) if project_id.nil? || type_id.nil?

      cache = RequestStore.store[CACHE_KEY] ||= {}
      key = [project_id, type_id, context]
      cache.fetch(key) { cache[key] = resolve(project, type, context) }
    rescue ArgumentError
      raise
    rescue StandardError => e
      raise if raise_on_error

      report(e, project, type, context)
      native(:error, context, error: true)
    end

    # Resolves up to 500 (project, type, context) keys. Returns a hash keyed by those triples.
    def for_many(project_ids:, type_ids:, contexts:)
      project_ids = Array(project_ids).compact.uniq
      type_ids = Array(type_ids).compact.uniq
      contexts = Array(contexts).map { |context| normalize_context(context) }.uniq
      pairs = project_ids.product(type_ids, contexts)
      raise ArgumentError, "at most #{MAX_FOR_MANY} keys are supported" if pairs.size > MAX_FOR_MANY

      projects = Project.where(id: project_ids).index_by(&:id)
      types = Type.where(id: type_ids).index_by(&:id)
      pairs.index_with do |project_id, type_id, context|
        project = projects[project_id]
        type = types[type_id]
        if project.nil? || type.nil?
          native(:no_scheme, context)
        else
          self.for(project, type, context)
        end
      end
    end

    # A compact type x context grid for project settings, resolved from a single scheme load and
    # without loading sections or items.
    def matrix(project)
      project_id = id_of(project)
      return {} if project_id.nil?

      type_ids = project.enabled_types.order(:position).pluck(:id)
      assignment = project_assignment(project_id)
      reason = assignment.nil? ? "no_scheme" : "scheme_inactive"
      if assignment.nil? || !assignment.scheme_active?
        return empty_matrix(type_ids, reason)
      end

      items = ScreenSchemeItem.where(scheme_id: assignment.scheme_id).to_a
      screens = screens_for(items)
      by_type = items.index_by(&:type_id)

      type_ids.to_h do |type_id|
        item = by_type[type_id]
        if item.nil?
          [type_id, grid_row(nil, "type_not_in_scheme", {})]
        else
          row = ScreenScheme::CONTEXTS.to_h do |context|
            screen, skipped = choose_screen(item, context, screens)
            [context, screen ? screen_cell(screen, skipped) : native_cell("no_usable_screen", skipped)]
          end
          [type_id, row]
        end
      end
    end

    def reset_cache
      RequestStore.store.delete(CACHE_KEY) if defined?(RequestStore)
      ::FieldRules::Resolver.reset_cache if defined?(::FieldRules::Resolver)
    end

    def normalize_context(context)
      normalized = context.to_sym
      raise ArgumentError, "invalid screen context #{context.inspect}" unless CONTEXTS.include?(normalized)

      normalized
    end

    def id_of(record)
      record.respond_to?(:id) ? record.id : record
    end

    def resolve(project, type, context)
      return native(:type_not_in_project, context) unless type_in_project?(project, type)

      assignment = project_assignment(project.id)
      return native(:no_scheme, context) if assignment.nil?
      return native(:scheme_inactive, context) unless assignment.scheme_active?

      item = ScreenSchemeItem.where(scheme_id: assignment.scheme_id, type_id: type.id).first
      return native(:type_not_in_scheme, context) if item.nil?

      screen, skipped = choose_screen(item, context)
      return native(:no_usable_screen, context, skipped:) if screen.nil?

      loaded = Screen.includes(sections: :items).find(screen.id)
      build_screen(project, type, context, loaded, skipped)
    end

    def type_in_project?(project, type)
      ProjectType.exists?(project_id: project.id, type_id: type.id)
    end

    def project_assignment(project_id)
      ProjectScreenScheme
        .joins(:scheme)
        .where(project_id:)
        .select("project_screen_schemes.*, screen_schemes.active AS scheme_active")
        .first
    end

    def screens_for(items)
      ids = items.flat_map do |item|
        ScreenScheme::SLOTS.values.map { |slot| item.public_send(:"#{slot}_id") }
      end.compact.uniq
      Screen.where(id: ids).index_by(&:id)
    end

    def choose_screen(item, context, screens = nil)
      skipped = []
      FALLBACKS.fetch(context).each do |slot|
        screen = slot_screen(item, slot, screens)
        next if screen.nil?
        next skipped << { slot: slot, screenId: screen.id, reason: "inactive" } unless screen.active?
        next skipped << { slot: slot, screenId: screen.id, reason: "type_mismatch" } unless screen.screen_type == slot.to_s

        return [screen, skipped]
      end
      [nil, skipped]
    end

    def slot_screen(item, slot, screens)
      column = ScreenScheme::SLOTS.fetch(slot)
      if screens
        screens[item.public_send(:"#{column}_id")]
      else
        item.public_send(column)
      end
    end

    def build_screen(project, type, context, screen, skipped)
      field_rules = field_rules_for(project, type)
      all_items = screen.sections.flat_map(&:items)

      unavailable = all_items.reject { |item| fields_available?(item.field_key, project, type) }.map(&:field_key).uniq
      hidden = all_items.select { |item| field_rules&.hidden?(item.field_key) }.map(&:field_key).uniq
      not_visible = all_items.reject(&:visible).map(&:field_key).uniq
      placed = all_items.select(&:visible).map(&:field_key).to_set
      required_not_placed = context == :create ? RequiredSet.for(project, type).reject { |key| placed.include?(key) } : []

      sections = screen.sections.map do |section|
        fields = section.items
                        .sort_by { |item| [item.position.to_i, item.id.to_i] }
                        .select { |item| visible_field?(item, project, type, field_rules) }
                        .map { |item| build_field(item, field_rules) }
        { id: section.id, name: section.name, position: section.position, fields: fields }
      end

      ResolvedScreen.new(
        source: :screen,
        reason: nil,
        context: context.to_s,
        screen:,
        sections:,
        state_source: field_rules ? "field_rules" : nil,
        diagnostics: {
          unavailable:,
          hidden_but_placed: hidden,
          required_not_placed:,
          not_visible:,
          skipped:,
          empty_create_screen: screen.create? && all_items.empty?,
          error: false
        }
      )
    end

    def visible_field?(item, project, type, field_rules)
      item.visible &&
        fields_available?(item.field_key, project, type) &&
        !field_rules&.hidden?(item.field_key)
    end

    def fields_available?(key, project, type)
      ::Screens::Fields.available?(key, project:, type:)
    end

    def build_field(item, field_rules)
      state = if field_rules
                { required: field_rules.required?(item.field_key),
                  readOnly: field_rules.read_only?(item.field_key),
                  defaultValue: field_rules[item.field_key]&.default_value }
              end
      { key: item.field_key,
        label: ::Screens::Fields.label(item.field_key),
        position: item.position,
        width: item.width,
        state: state }
    end

    def field_rules_for(project, type)
      return nil unless defined?(::FieldRules::Resolver)

      ::FieldRules::Resolver.for(project, type)
    rescue StandardError
      nil
    end

    def native(reason, context, skipped: [], error: false)
      ResolvedScreen.new(
        source: :native,
        reason: reason.to_s,
        context: context.to_s,
        screen: nil,
        sections: [],
        state_source: nil,
        diagnostics: {
          unavailable: [],
          hidden_but_placed: [],
          required_not_placed: [],
          not_visible: [],
          skipped:,
          empty_create_screen: false,
          error:
        }
      )
    end

    def report(error, project, type, context)
      OpenProject.logger.error(
        "[screens] resolving layout failed, using native layout: #{error.class}: #{error.message}"
      )
      Rails.error.report(error, handled: true,
                                context: { project_id: id_of(project), type_id: id_of(type), context: })
    rescue StandardError
      nil
    end

    def empty_matrix(type_ids, reason)
      type_ids.to_h { |type_id| [type_id, grid_row(nil, reason, {})] }
    end

    def grid_row(_screen, reason, contexts)
      ScreenScheme::CONTEXTS.to_h do |context|
        cell = contexts[context]
        [context, cell || native_cell(reason, [])]
      end
    end

    def screen_cell(screen, skipped)
      { source: "screen", reason: nil, screen_id: screen.id, screen_name: screen.name, skipped: }
    end

    def native_cell(reason, skipped)
      { source: "native", reason: reason.to_s, screen_id: nil, screen_name: nil, skipped: }
    end
  end
end
