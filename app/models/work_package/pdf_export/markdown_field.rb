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

module WorkPackage::PDFExport::MarkdownField
  include WorkPackage::PDFExport::Markdown
  PREFORMATTED_BLOCKS = %w(pre code).freeze

  def write_markdown_field!(work_package, markdown, label)
    return if markdown.blank?

    write_optional_page_break
    with_margin(styles.wp_markdown_label_margins) do
      pdf.formatted_text([styles.wp_markdown_label.merge({ text: label })])
    end
    with_margin(styles.wp_markdown_margins) do
      write_markdown! work_package, apply_markdown_field_macros(markdown, work_package)
    end
  end

  private

  def apply_markdown_field_macros(markdown, work_package)
    apply_macros(markdown, work_package, WorkPackage::Exports::Macros::Attributes)
  end

  def apply_macros(markdown, work_package, formatter)
    return markdown unless formatter.applicable?(markdown)

    document = Markly.parse(markdown)
    document.walk do |node|
      if node.type == :html
        node.string_content = apply_macro_html(node.string_content, work_package, formatter) || node.string_content
      elsif node.type == :text
        node.string_content = apply_macro_text(node.string_content, work_package, formatter) || node.string_content
      end
    end
    document.to_markdown
  end

  def apply_macro_text(text, work_package, formatter)
    return text unless formatter.applicable?(text)

    text.gsub!(formatter.regexp) do |matched_string|
      matchdata = Regexp.last_match
      formatter.process_match(matchdata, matched_string, { user: User.current, work_package: })
    end
  end

  def apply_macro_html(html, work_package, formatter)
    return html unless formatter.applicable?(html)

    doc = Nokogiri::HTML.fragment(html)
    apply_macro_html_node(doc, work_package, formatter)
    doc.to_html
  end

  def apply_macro_html_node(node, work_package, formatter)
    if node.text?
      node.content = apply_macro_text(node.content, work_package, formatter)
    elsif PREFORMATTED_BLOCKS.exclude?(node.name)
      node.children.each { |child| apply_macro_html_node(child, work_package, formatter) }
    end
  end
end
