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

module WorkPackage::PDFExport::Style
  def page_size
    'EXECUTIVE' # TODO: 'A4'?
  end

  def page_header_top
    20
  end

  def page_bottom_margin
    60
  end

  def page_footer_top
    30
  end

  def page_logo_height
    20
  end

  def page_logo_align
    :right
  end

  def page_top_margin
    60
  end

  def page_heading_style
    { size: 14, styles: [:bold] }
  end

  def page_heading_margins_style
    { margin_bottom: 10 }
  end

  def page_header_style
    { size: 8, style: :normal }
  end

  def page_footer_style
    { size: 8, style: :normal }
  end

  def overview_table_link_color
    '175A8E'
  end

  def overview_group_header_style
    { size: 11, styles: [:bold] }
  end

  def overview_group_header_margins_style
    { margin_bottom: 10 }
  end

  def overview_table_margins_style
    { margin_bottom: 20, margin_left: 0, margin_right: 0 }
  end

  def overview_table_header_cell_style
    { size: 9, text_color: "000000", font_style: :bold,
      padding_left: 5, padding_right: 5, padding_top: 0, padding_bottom: 5 }
  end

  def overview_table_sums_cell_style
    { size: 8, text_color: "000000", font_style: :bold }
  end

  def overview_table_subject_indent_style
    8
  end

  def overview_table_cell_padding_style
    { padding_left: 5,
      padding_right: 5,
      padding_top: 0,
      padding_bottom: 5 }
  end

  def overview_table_cell_style
    { size: 9,
      text_color: "000000",
      border_widths: [0.25, 0.25, 0.25, 0.25] }
  end

  def toc_margins_style
    { margin_bottom: 20 }
  end

  def toc_item_index_style
    { size: 10, style: :bold }
  end

  def toc_item_subject_font_style
    { size: 10 }
  end

  def toc_item_subject_indent_style
    4
  end

  def toc_item_page_nr_font_style
    { size: 10 }
  end

  def toc_item_margins_style
    { margin_bottom: 4 }
  end

  def wp_headline_margins_style
    { margin_top: 4, margin_bottom: 4 }
  end

  def wp_headline_style
    { size: 9, styles: [:bold] }
  end

  def wp_item_margins_style
    { margin_left: 10 }
  end

  def wp_item_style
    { size: 9, styles: [:italic] }
  end

  def wp_label_margins_style
    { margin_top: 12, margin_bottom: 8 }
  end

  def wp_label_style
    { size: 11, styles: [:bold] }
  end

  def wp_detail_margins_style
    { margin_bottom: 20 }
  end

  def wp_detail_subject_margins_style
    { margin_bottom: 4 }
  end

  def wp_detail_subject_font_style
    { size: 14, styles: [:bold] }
  end

  def wp_attributes_table_margins_style
    { margin_top: 4, margin_bottom: 2 }
  end

  def wp_attributes_table_label_font_style
    { font_style: :bold }
  end

  def wp_attributes_table_cell_style
    { size: 9,
      text_color: "000000",
      border_widths: [0.25, 0.25, 0.25, 0.25],
      padding_left: 5,
      padding_right: 5,
      padding_top: 0,
      padding_bottom: 4 }
  end

  def wp_markdown_field_label_size
    12
  end

  def wp_markdown_field_margins_style
    { margin_top: 12, margin_bottom: 8 }
  end

  def markdown_styling_yml
    # rubocop:disable Naming/VariableNumber
    {
      header: {
        size: 8,
        styles: [:bold]
      },
      header_1: {
        size: 10,
        padding_bottom: 4
      },
      header_2: {
        size: 10
      },
      header_3: {
        size: 9
      },
      page: {
        size: 10,
        leading: 3
      },
      paragraph: {
        align: 'left'
      },
      unordered_list: {
        spacing: 1
      },
      unordered_list_point: {
        spacing: 4
      },
      ordered_list: {
        spacing: 1
      },
      ordered_list_point: {
        spacing: 4
      },
      task_list: {
        spacing: 1
      },
      task_list_point: {
        spacing: 4,
        checked: '☑', # fallback font is needed
        unchecked: '☐' # fallback font is needed
      },
      link: {
        color: '175A8E',
        styles: []
      },
      code: {
        color: '880000',
        size: 9,
        font: 'SpaceMono'
      },
      blockquote: {
        background_color: 'f4f9ff',
        size: 10,
        styles: ['italic'],
        color: '0f3b66',
        border_color: 'b8d6f4',
        border_width: 1,
        padding: 4,
        padding_left: 6,
        margin_top: 4,
        margin_bottom: 4,
        no_border_left: false,
        no_border_right: true,
        no_border_bottom: true,
        no_border_top: true
      },
      image: {
        align: 'left'
      },
      codeblock: {
        background_color: 'F5F5F5',
        color: '880000',
        padding: '3mm',
        size: 8,
        margin_top: '2mm',
        margin_bottom: '2mm',
        font: 'SpaceMono'
      },
      table: {
        auto_width: true,
        margin_top: 4,
        margin_bottom: 4,
        header: {
          size: 9,
          styles: ['bold'],
          background_color: 'F0F0F0'
        },
        cell: {
          size: 9,
          border_width: '0.25mm',
          padding: 5
        }
      }
    }
    # rubocop:enable Naming/VariableNumber
  end
end
