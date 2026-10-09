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

class My::LocaleForm < ApplicationForm
  include Redmine::I18n

  form do |f|
    f.select_list(
      name: :language,
      label: attribute_name(:language),
      required: true,
      include_blank: include_auto? ? I18n.t(:label_auto_option) : false,
      input_width: :medium
    ) do |list|
      available_languages.each do |label, value|
        list.option(label:, value:, lang: value)
      end
    end

    f.fields_for(:pref, model.pref, nested: false) do |builder|
      ::My::TimeZoneForm.new(builder)
    end

    f.fields_for(:pref, model.pref, nested: false) do |builder|
      ::My::DateTimeFormatForm.new(builder)
    end

    f.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
  end

  private

  def include_auto?
    valid_languages.to_set == all_languages.to_set
  end

  def available_languages
    @available_languages ||= valid_languages
      .map { translate_language(it) }
      .sort_by(&:first)
  end
end
