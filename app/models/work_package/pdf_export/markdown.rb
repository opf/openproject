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

module WorkPackage::PDFExport::Markdown

  def write_markdown!(work_package, markdown)
    write_content! work_package, markdown
  end

  private

  def write_content!(work_package, markdown)
    configure_markup work_package
    #CommonMarker.render_doc(content, CM_PARSE_OPTIONS, CM_EXTENSIONS)

    markup = format_text(markdown, object: work_package, format: :html)
               .gsub('class="op-uc-image"', 'style="width:100"') # TODO: this is a workaround image formatting
    pdf.markup markup
  end

  def configure_markup(work_package)
    # configure prawn markup gem in context of our work package
    pdf.markup_options = markup_options.merge(
      {
        image: {
          loader: ->(src) {
            with_attachments? ? attachment_image_filepath(work_package, src) : nil
          },
          placeholder: "<i>[#{I18n.t('export.image.omitted')}]</i>"
        }
      }
    )
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

  def markup_options
    { text: markup_font_style,
      heading1: markup_h1_style,
      heading2: markup_h2_style,
      heading3: markup_h3_style,
      heading4: markup_h4_style,
      heading5: markup_h5_style,
      heading6: markup_h6_style }
  end

  def markup_h1_style
    { size: 10, styles: [:bold] }
  end

  def markup_h2_style
    { size: 10, styles: [:bold] }
  end

  def markup_h3_style
    { size: 9, styles: [:bold] }
  end

  def markup_h4_style
    { size: 8, styles: [:bold] }
  end

  def markup_h5_style
    { size: 8, styles: [:bold] }
  end

  def markup_h6_style
    { size: 10, styles: [:bold] }
  end

  def markup_font_style
    { style: :normal, size: 9 }
  end

end
