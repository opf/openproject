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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class DocumentForm < ApplicationForm
  form do |f|
    f.select_list(
      name: :type_id,
      label: I18n.t("label_document_type"),
      input_width: :medium,
      required: true
    ) do |select|
      DocumentType.find_each do |type|
        select.option(value: type.id, label: type.name)
      end
    end

    f.text_field(
      name: :title,
      label: I18n.t("label_document_title"),
      required: true
    )

    f.rich_text_area(
      name: :description,
      label: I18n.t("label_document_description"),
      classes: "document-form--long-description",
      rich_text_options: {
        with_text_formatting: true,
        resource:,
        turboMode: false
      }
    )

    f.hidden(name: :kind, value: "classic")

    f.submit(
      name: :save,
      label: save_label,
      scheme: :primary
    ) do |button|
      button.with_leading_visual_icon(icon: :check)
    end
  end

  private

  def resource
    return unless model

    API::V3::Documents::DocumentRepresenter.create(
      model, current_user: User.current, embed_links: true
    )
  end

  def save_label
    if model.persisted?
      I18n.t("button_save")
    else
      I18n.t("button_create")
    end
  end
end
