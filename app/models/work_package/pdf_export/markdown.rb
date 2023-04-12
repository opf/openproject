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

require 'md_to_pdf/core'

module WorkPackage::PDFExport::Markdown
  class MD2PDF
    include MarkdownToPDF::Core

    def initialize(styling_yml)
      @styles = MarkdownToPDF::Styles.new(styling_yml)
      init_options({ auto_generate_header_ids: false })
      # @hyphens = Hyphen.new('en', false)
    end

    def draw_markdown(markdown, pdf, image_loader)
      @pdf = pdf
      @image_loader = image_loader
      cm_extentions = %i[autolink strikethrough table tagfilter tasklist]
      cm_parse_option = %i[FOOTNOTES SMART LIBERAL_HTML_TAG STRIKETHROUGH_DOUBLE_TILDE UNSAFE VALIDATE_UTF8]
      root = CommonMarker.render_doc(markdown, cm_parse_option, cm_extentions)
      begin
        draw_node(root, pdf_root_options(@styles.page), true)
      rescue StandardError => e
        Rails.logger.error "Failed to draw markdown pdf: #{e}"
      end
    end

    def image_url_to_local_file(url, _node)
      return nil if url.blank? || @image_loader.nil?

      @image_loader.call(url)
    end

    def hyphenate(text)
      text # @hyphens.hyphenate(text)
    end

    def handle_unknown_inline_html_tag(tag, _node, opts)
      result = []
      case tag.name
      when 'mention'
        # <mention class="mention" data-id="46012" data-type="work_package" data-text="#46012"></mention>
        # <mention class="mention" data-id="3" data-type="user" data-text="@Some User">@Some User</mention>
        if tag.text.blank?
          text = tag.attr('data-text')
          result.push(text_hash(text, opts)) if text.present?
        end
      when 'span'
        text = tag.text
        result.push(text_hash(text, opts)) if text.present?
      else
        result.push(text_hash(tag.to_s, opts))
      end
      [result, opts]
    end

    def handle_unknown_html_tag(tag, node, opts)
      case tag.name
      when 'figure', 'div', 'p'
        # nop, but scan children [true, ...]
      else
        draw_formatted_text([text_hash(tag.to_s, opts)], opts, node)
        return [false, opts]
      end
      [true, opts]
    end

    def warn(text, element, node)
      Rails.logger.warn "PDF-Export: #{text}\nGot #{element} at #{node.sourcepos.inspect}\n\n"
    end
  end

  def write_markdown!(work_package, markdown)
    md2pdf = MD2PDF.new(styling_yml)
    md2pdf.draw_markdown(markdown, pdf, ->(src) {
      with_attachments? ? attachment_image_filepath(work_package, src) : nil
    })
  end

  private

  def styling_yml
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
        styles: ['underline']
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

  def attachment_image_filepath(work_package, src)
    # images are embedded into markup with the api-path as img.src
    attachment = attachment_by_api_content_src(work_package, src)
    return nil if attachment.nil? || attachment.file.local_file.nil? || !pdf_embeddable?(attachment)

    resize_image(attachment.file.local_file.path)
  end

  def attachment_by_api_content_src(work_package, src)
    # find attachment by api-path
    work_package.attachments.detect { |a| api_url_helpers.attachment_content(a.id) == src }
  end
end
