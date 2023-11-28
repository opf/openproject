# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
#
module OpenProject::Common
  class ClipboardCopyComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    options visually_hide_label: true,
            readonly: true,
            required: false,
            input_group_options: {}

    def text_field_options
      { name: options[:name],
        label: options[:label],
        classes: "rounded-right-0",
        visually_hide_label:,
        value: value_to_copy,
        inset: true,
        readonly:,
        required: }.merge(input_group_options)
    end

    def clipboard_copy_options
      { value: value_to_copy,
        aria: { label: clipboard_copy_aria_label },
        classes: clipboard_copy_classes }.merge(input_group_options)
    end

    private

    def clipboard_copy_classes
      %w[Button Button--iconOnly Button--secondary Button--medium rounded-left-0 border-left-0].tap do |classes|
        classes << "mt-4" unless visually_hide_label
      end
    end

    def clipboard_copy_aria_label
      options[:clipboard_copy_aria_label] || I18n.t('button_copy_to_clipboard')
    end

    def value_to_copy
      options[:value_to_copy]
    end
  end
end
