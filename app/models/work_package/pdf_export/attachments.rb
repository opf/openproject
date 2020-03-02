#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module WorkPackage::PDFExport::Attachments
  ##
  # Creates cells for each attachment of the work package
  #
  def make_attachments_cells(attachments)
    # Distribute all attachments on one line, this will work well with up to ~5 attachments.
    # more than that will be resized further
    available_width = (pdf.bounds.width / attachments.length) * 0.98

    attachments
      .map { |attachment| make_attachment_cell attachment, available_width }
      .compact
  end

  private

  def make_attachment_cell(attachment, available_width)
    # We can only include JPG and PNGs, maybe we want to add a text box for other attachments here
    return nil unless pdf_embeddable?(attachment)

    # Access the local file. For Carrierwave attachments, this will be blocking.
    file_path = attachment.file.local_file.path
    # Fit the image roughly in the center of each cell
    pdf.make_cell(image: file_path, fit: [available_width, 125], position: :center)
  rescue => e
    Rails.logger.error { "Failed to attach work package image to PDF: #{e} #{e.message}" }
    nil
  end

  def pdf_embeddable?(attachment)
    %w[image/jpeg image/png].include?(attachment.content_type)
  end
end
