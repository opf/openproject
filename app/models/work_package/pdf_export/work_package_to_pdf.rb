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

class WorkPackage::PDFExport::WorkPackageToPdf < Exports::Exporter
  include WorkPackage::PDFExport::Common
  include WorkPackage::PDFExport::Attachments
  include WorkPackage::PDFExport::WorkPackageDetail
  include WorkPackage::PDFExport::Page
  include WorkPackage::PDFExport::Style

  attr_accessor :pdf, :columns

  self.model = WorkPackage

  alias :work_package :object

  def self.key
    :pdf
  end

  def initialize(work_package, _options = {})
    super

    self.columns = ::Query.available_columns(work_package.project)
    setup_page!
  end

  def export!
    render_work_package
    success(pdf.render)
  rescue StandardError => e
    Rails.logger.error { "Failed to generated PDF export: #{e} #{e.message}}." }
    error(I18n.t(:error_pdf_failed_to_export, error: e.message))
  end

  def setup_page!
    self.pdf = get_pdf(current_language)
    @page_count = 0
    configure_page_size!(:portrait)
  end

  def render_work_package
    write_title!
    write_work_package_detail_content!(work_package)
    write_headers!
    write_footers!
  end

  def heading
    "#{work_package.type} ##{work_package.id} - #{work_package.subject}"
  end

  def footer_title
    work_package.project.name
  end

  def title
    # <project>_<type>_<ID>_<subject><YYYY-MM-DD>_<HH-MM>.pdf
    build_pdf_filename([work_package.project, work_package.type,
                        "##{work_package.id}", work_package.subject].join("_"))
  end

  def with_images?
    true
  end
end
