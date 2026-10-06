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
    include Settings::FormHelper

    option :section
    option :form_hook, optional: true

    settings_form do |sf|
      helpers.call_hook(form_hook, form: sf) if form_hook

      section.visible_entries.each do |entry|
        sf.public_send(entry.input, name: entry.name, **input_options(entry))
      end
    end

    private

    def input_options(entry)
      options = entry.input_options
      options[:caption] = caption(entry) unless options.key?(:caption)
      options.merge!(unit_options(entry.name, entry.ui[:unit])) if entry.ui[:unit]
      options.compact
    end

    def caption(entry)
      case caption = entry.ui[:caption]
      when Proc then @view_context.instance_exec(&caption)
      when Symbol then @view_context.t(caption)
      when nil then setting_caption(entry.name)
      else caption
      end
    end

    def unit_options(name, unit)
      id = "settings_#{name}_unit"

      {
        trailing_visual: { text: { id:, text: I18n.t(unit) } },
        aria: { describedby: id }
      }
    end
  end
end
