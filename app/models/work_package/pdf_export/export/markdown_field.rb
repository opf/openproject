#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module WorkPackage::PDFExport::Export::MarkdownField
  include WorkPackage::PDFExport::Export::Markdown
  include WorkPackage::PDFExport::Common::Macro

  def write_markdown_field!(work_package, markdown, label)
    return if markdown.blank?

    write_optional_page_break
    write_markdown_field_label(label)
    write_markdown_field_value(work_package, markdown)
  end

  private

  def write_markdown_field_label(label)
    with_margin(styles.wp_markdown_label_margins) do
      pdf.formatted_text([styles.wp_markdown_label.merge({ text: label })])
    end
  end

  def write_markdown_field_value(work_package, markdown)
    with_margin(styles.wp_markdown_margins) do
      write_markdown!(
        work_package,
        apply_markdown_field_macros(markdown, work_package),
        styles.wp_markdown_styling_yml
      )
    end
  end
end
