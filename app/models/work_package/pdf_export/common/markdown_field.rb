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

module WorkPackage::PDFExport::Common::MarkdownField
  include Exports::PDF::Common::Markdown
  include Exports::PDF::Common::Macro

  def write_markdown_field!(work_package, markdown, label)
    return if markdown.blank?

    write_optional_page_break
    write_markdown_field_label(label) if label.present?
    write_markdown_field_value(work_package, markdown)
  end

  private

  def write_markdown_field_label(label)
    style = styles.markdown_field_label
    with_margin(styles.markdown_field_label_margins) do
      pdf.formatted_text([style.merge({ text: label })], style)
    end
  end

  def write_markdown_field_value(work_package, markdown)
    with_margin(styles.markdown_field_margins) do
      write_markdown!(
        apply_markdown_field_macros(markdown,
                                    { work_package:, project: work_package.project, user: User.current }),
        styles.markdown_field_styling_yml
      )
    end
  end
end
