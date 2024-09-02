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

require "md_to_pdf/core"

module WorkPackage::PDFExport::Markdown
  class MD2PDF
    include MarkdownToPDF::Core
    include MarkdownToPDF::Parser

    def initialize(styling_yml, pdf)
      @styles = MarkdownToPDF::Styles.new(styling_yml)
      init_options({ auto_generate_header_ids: false })
      pdf_init_md2pdf_fonts(pdf)
      # @hyphens = Hyphen.new('en', false)
    end

    def draw_markdown(markdown, pdf, image_loader)
      @pdf = pdf
      @image_loader = image_loader
      root = parse_markdown(markdown)
      begin
        draw_node(root, pdf_root_options(@styles.page), true)
      rescue Prawn::Errors::CannotFit => e
        Rails.logger.error "Failed to draw markdown field to pdf because of non fitting content: #{e}"
      end
    end

    def image_url_to_local_file(url, _node = nil)
      return nil if url.blank? || @image_loader.nil?

      @image_loader.call(url)
    end

    def hyphenate(text)
      text # @hyphens.hyphenate(text)
    end

    def handle_mention_html_tag(tag, node, opts)
      if tag.text.blank?
        # <mention class="mention" data-id="46012" data-type="work_package" data-text="#46012"></mention>
        # <mention class="mention" data-id="3" data-type="user" data-text="@Some User">
        text = tag.attr("data-text")
        if text.present? && !node.next.respond_to?(:string_content) && node.next.string_content != text
          return [text_hash(text, opts)]
        end
      end
      # <mention class="mention" data-id="3" data-type="user" data-text="@Some User">@Some User</mention>
      []
    end

    def handle_unknown_inline_html_tag(tag, node, opts)
      result = if tag.name == "mention"
                 handle_mention_html_tag(tag, node, opts)
               else
                 # unknown/unsupported html tags eg. <foo>hi</foo> are ignored
                 # but scanned for supported or text children
                 data_inlinehtml_tag(tag, node, opts)
               end
      [result, opts]
    end

    def handle_unknown_html_tag(_tag, _node, opts)
      # unknown/unsupported html tags eg. <foo>hi</foo> are ignored
      # but scanned for supported or text children [true, ...]
      [true, opts]
    end

    def warn(text, element, node)
      Rails.logger.warn "PDF-Export: #{text}\nGot #{element} at #{node.source_position.inspect}\n\n"
    end
  end

  def write_markdown!(work_package, markdown)
    md2pdf = MD2PDF.new(styles.wp_markdown_styling_yml, pdf)
    md2pdf.draw_markdown(markdown, pdf, ->(src) {
      with_images? ? attachment_image_filepath(work_package, src) : nil
    })
  end

  private

  def attachment_image_local_file(attachment)
    attachment.file.local_file
  rescue StandardError => e
    Rails.logger.error "Failed to access attachment #{attachment.id} file: #{e}"
    nil # return nil as if the id was wrong and the attachment obj has not been found
  end

  def attachment_image_filepath(work_package, src)
    # images are embedded into markup with the api-path as img.src
    attachment = attachment_by_api_content_src(work_package, src)
    return nil if attachment.nil? || !pdf_embeddable?(attachment.content_type)

    local_file = attachment_image_local_file(attachment)
    return nil if local_file.nil?

    resize_image(local_file.path)
  end

  def attachment_by_api_content_src(work_package, src)
    # find attachment by api-path
    work_package.attachments.detect { |a| api_url_helpers.attachment_content(a.id) == src }
  end
end
