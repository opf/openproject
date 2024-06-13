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

class WorkPackage::PDFExport::DocumentGenerator < Exports::Exporter
  include WorkPackage::PDFExport::Common::Common
  include WorkPackage::PDFExport::Common::Attachments
  include WorkPackage::PDFExport::Common::Logo
  include WorkPackage::PDFExport::Common::Macro
  include WorkPackage::PDFExport::Generator::Generator

  attr_accessor :pdf

  self.model = WorkPackage

  alias :work_package :object

  def self.key
    :generate_pdf
  end

  def initialize(work_package, _options = {})
    super

    setup_page!
  end

  def setup_page!
    self.pdf = get_pdf(current_language)
  end

  def export!
    render_doc
    success(pdf.render)
  rescue StandardError => e
    Rails.logger.error { "Failed to generate PDF: #{e} #{e.message}}." }
    error(I18n.t(:error_pdf_failed_to_export, error: e.message))
  end

  def render_doc
    generate_doc!(
      work_package,
      apply_markdown_field_macros(work_package.description || "", work_package),
      "contracts.yml"
    )
  end

  def heading
    "#{work_package.type} ##{work_package.id} - #{work_package.subject}"
  end

  def footer_title
    work_package.name
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
