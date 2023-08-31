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

class ColorsForm < ApplicationForm
  form do |colors_form|
    colors_form.text_field(
      label: attribute_name(:name),
      name: :name,
      required: true
    )

    colors_form.text_field(
      label: attribute_name(:hexcode),
      name: :hexcode,
      required: true,
      maxlength: 7
    )

    colors_form.separator

    colors_form.group(layout: :horizontal) do |button_group|
      button_group.submit(
        scheme: :primary,
        name: 'save',
        label: I18n.t(:button_save)
      )

      button_group.button(
        label: I18n.t(:button_cancel),
        name: 'cancel',
        tag: :a,
        href: url_helpers.colors_path
      )
    end
  end

  def attribute_name(field)
    @builder.object.class.human_attribute_name(field)
  end
end
