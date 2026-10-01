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

require "md_to_pdf/core"
require "md_to_pdf/hyphen"

module WorkPackage::PDFExport::Generator::Generator
  class MD2PDFGenerator
    include MarkdownToPDF::Core
    include MarkdownToPDF::Parser
    include MarkdownToPDF::StyleSchema
    include Exports::PDF::Common::WorkPackageMentions

    def initialize(styling_yml)
      symbol_yml = symbolize(styling_yml)
      symbol_yml[:page][:font] = Exports::PDF::Common::View::default_font
      validate_schema!(symbol_yml, styles_schema)
      @styles = MarkdownToPDF::Styles.new(symbol_yml)
      init_options({ auto_generate_header_ids: false })
    end

    def init_pdf(pdf)
      @pdf = pdf
      init_pdf_page_styles(pdf)
      pdf_init_md2pdf_fonts(pdf)
    end

    def init_pdf_page_styles(pdf)
      page_style = @styles.page
      page_margins = opts_margin(page_style)
      pdf.options[:page_layout] = (page_style[:page_layout] || "portrait").to_sym
      pdf.options[:page_size] = page_style[:page_size]
      %i[top_margin left_margin bottom_margin right_margin].each do |margin|
        pdf.options[margin] = page_margins[margin]
      end
    end

    def generate!(markdown, options, image_loader)
      @image_loader = image_loader
      fields = {}
                 .merge(@styles.default_fields)
                 .merge(options)
      doc = parse_frontmatter_markdown(markdown, fields)
      @hyphens = Hyphen.new(options[:language], true) if options[:language].present?
      render_doc(doc)
    end

    def render_doc(doc)
      style = @styles.page
      opts = pdf_root_options(style)
      root = doc[:root]
      draw_node(root, opts, true)
      draw_footnotes(opts)
      repeating_page_footer(doc, opts)
      repeating_page_header(doc, opts)
      repeating_page_logo(doc[:logo], root, opts)
    end

    def image_url_to_local_file(url, _node = nil)
      return nil if url.blank? || @image_loader.nil?

      @image_loader.call(url)
    end

    def hyphenate(text)
      return text if @hyphens.nil?

      @hyphens.hyphenate(text)
    end

    def handle_wp_mention_html_tag(tag, node, opts)
      # <mention class="mention" data-id="185" data-type="work_package" data-text="#185">#185</mention>
      # <mention class="mention" data-id="185" data-type="work_package" data-text="##185">##185</mention>
      # <mention class="mention" data-id="185" data-type="work_package" data-text="###185">###185</mention>
      next_node = node&.next
      if next_node && next_node.type == :text && next_node.respond_to?(:string_content)
        next_node.string_content = ""
      end
      render_wp_mention(tag.attr("data-text") || "", tag.attr("data-id") || "", opts)
    end

    def render_wp_mention(content, id, opts)
      return [text_hash(content, opts)] if id.blank?

      work_package = WorkPackage.find_by_display_id(id)
      return [text_hash(content, opts)] unless work_package&.visible?

      [text_hash(expand_wp_mention(work_package, content), opts)]
    end

    def handle_mention_html_tag(tag, node, opts)
      if tag.attr("data-type") == "work_package"
        handle_wp_mention_html_tag(tag, node, opts)
      elsif tag.text.blank?
        # <mention class="mention" data-id="3" data-type="user" data-text="@Some User">
        text = tag.attr("data-text")
        if text.present? && !node.next.respond_to?(:string_content) && node.next.string_content != text
          return [text_hash(text, opts)]
        end
        []
      else
        # <mention class="mention" data-id="3" data-type="user" data-text="@Some User">@Some User</mention>
        []
      end
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

  def generate_doc!(markdown, styling_file)
    md2pdf = MD2PDFGenerator.new(md_to_pdf_styling(styling_file))
    md2pdf.init_pdf(pdf)
    md2pdf.generate!(markdown, md_to_pdf_options, ->(src) {
      if src == logo_image_filename
        logo_image_filename
      else
        attachment_image_filepath(src)
      end
    })
  end

  private

  def md_to_pdf_styling(styling_file)
    styling = YAML::load_file(File.join(styling_asset_path, styling_file))
    # overwrite the paper size if it is set in the options
    styling["page"]["page-size"] = options[:paper_size] if options[:paper_size].present?
    styling
  end

  def md_to_pdf_options
    # rubocop:disable Naming/VariableNumber
    {
      language: hyphenation_language,
      pdf_footer: footer_date,
      pdf_footer_2: footer_title,
      pdf_footer_3: I18n.t("pdf_generator.page_nr_footer", page: "<page>", total: "<total>"),
      pdf_header_logo: logo_image_filename,
      pdf_header: heading
    }.compact
    # rubocop:enable Naming/VariableNumber
  end

  def styling_asset_path
    File.dirname(File.expand_path(__FILE__))
  end
end
