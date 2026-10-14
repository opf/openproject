# frozen_string_literal: true

# -- copyright
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
# ++

module Settings
  class MultiLangForm < ApplicationForm
    include FormHelper

    attr_reader :name, :current_language

    def initialize(name:, current_language:)
      super()

      @name = name
      @current_language = current_language
    end

    form do |f|
      # Add hidden languages
      Redmine::I18n.valid_languages.each do |lang|
        f.hidden(
          name: lang,
          value: Setting.send(name)[lang],
          id: "lang-for-#{name}-#{lang}",
          data: { admin__multi_lang_text_setting_target: "langFor", lang: }
        )
      end

      # Add WYSIWYG
      f.rich_text_area(
        name: current_language,
        value: setting_value(name)[current_language],
        label: setting_label(name),
        disabled: setting_disabled?(name),
        visually_hide_label: true,
        rich_text_options: {
          turboMode: true,
          showAttachments: false
        },
        data: { admin__multi_lang_text_setting_target: "textArea" }
      )
    end
  end
end
