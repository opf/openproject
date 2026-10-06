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

module Settings
  class PageSectionForm < ApplicationForm
    extend Dry::Initializer[undefined: false]

    option :section
    option :form_hook, optional: true
    option :dependency_causes, default: proc { {} }

    settings_form do |sf|
      helpers.call_hook(form_hook, form: sf) if form_hook

      section.visible_entries.each do |entry|
        if entry.depends_on
          sf.group(**dependent_group_options(entry.depends_on)) { render_entry(it, entry) }
        else
          render_entry(sf, entry)
        end
      end
    end

    private

    def render_entry(form, entry)
      return instance_exec(form, entry, &entry.input) if entry.input.is_a?(Proc)

      submit_empty_selection(form, entry.name) if entry.input == :check_box_group
      form.public_send(entry.input, name: entry.name, **input_options(entry))
    end

    def input_options(entry)
      hints = evaluated_hints(entry)

      {
        **hints,
        label: entry.label(@view_context),
        caption: caption(entry),
        **unit_options(entry),
        **cause_options(entry, hints)
      }.compact
    end

    def evaluated_hints(entry)
      entry.input_options.transform_values { it.is_a?(Proc) ? @view_context.instance_exec(&it) : it }
    end

    def caption(entry)
      caption = entry.caption(@view_context)
      warning = entry.warning(@view_context)
      return caption unless warning

      @view_context.safe_join([
        (render(Primer::Beta::Text.new(tag: :p)) { caption } if caption),
        render(Primer::OpenProject::InlineMessage.new(scheme: :warning, size: :small)) do
          render(Primer::Beta::Text.new(tag: :p)) do
            @view_context.safe_join([render(Primer::Beta::Text.new(tag: :strong)) { "#{I18n.t(:warning)}:" }, warning], " ")
          end
        end
      ].compact)
    end

    def cause_options(entry, hints)
      return {} unless dependency_causes.key?(entry.name)

      target = dependency_causes[entry.name] == :value ? :show_when_value_selected_target : :show_when_checked_target
      { data: { **hints.fetch(:data, {}), target => "cause", target_name: entry.name } }
    end

    def dependent_group_options(dependency)
      cause = dependency[:setting]

      if dependency.key?(:value)
        {
          hidden: Setting[cause].to_s != dependency[:value].to_s,
          data: { show_when_value_selected_target: "effect", target_name: cause, value: dependency[:value] }
        }
      else
        {
          hidden: !Setting[cause],
          data: { show_when_checked_target: "effect", show_when: "checked", target_name: cause }
        }
      end
    end

    def submit_empty_selection(form, name)
      form.hidden(name: "settings[#{name}][]", value: "", scope_name_to_model: false, scope_id_to_model: false)
    end

    def unit_options(entry)
      unit = entry.unit(@view_context)
      return {} unless unit

      id = "settings_#{entry.name}_unit"

      {
        trailing_visual: { text: { id:, text: unit } },
        aria: { describedby: id }
      }
    end
  end
end
