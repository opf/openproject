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

module WorkPackage::PDFExport::MarkdownField
  include WorkPackage::PDFExport::Markdown

  def write_markdown_field!(work_package, markdown, label)
    return if markdown.blank?

    # TODO: move page break threshold const to style settings and implement conditional break with height measuring
    write_optional_page_break(100)
    write_field_label! label
    write_markdown! work_package, markdown
  end

  def write_field_label!(label)
    with_margin(label_margins_style) do
      pdf.formatted_text([label_style.merge({ text: label })])
    end
  end

  private

  def label_margins_style
    { margin_top: 12, margin_bottom: 8 }
  end

  def label_style
    { size: 11, styles: [:bold] }
  end
end
