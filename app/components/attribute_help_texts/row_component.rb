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

class AttributeHelpTexts::RowComponent < OpPrimer::BorderBoxRowComponent
  alias_method :attribute_help_text, :model

  def row_data
    { test_selector: "attribute-help-text-row-#{attribute_help_text.id}" }
  end

  def attribute_name
    render(Primer::Beta::Link.new(href: edit_attribute_help_text_path(attribute_help_text))) do
      attribute_help_text.attribute_field_name
    end
  end

  def help_text
    render(OpenProject::Common::AttributeHelpTextComponent.new(help_text: attribute_help_text)) do |help_text|
      help_text.with_additional_label_content(t(:"attribute_help_texts.show_preview"))
    end
  end

  def button_links
    [delete_link]
  end

  private

  def delete_link
    render(
      Primer::Beta::IconButton.new(
        icon: :trash,
        scheme: :danger,
        tag: :a,
        href: attribute_help_text_path(attribute_help_text),
        "aria-label": t(:button_delete),
        tooltip_direction: :w,
        test_selector: "attribute-help-text-delete-#{attribute_help_text.id}",
        data: {
          turbo_method: :delete,
          turbo_confirm: t(:text_are_you_sure)
        }
      )
    )
  end
end
