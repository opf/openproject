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

# Exporter for work package table.
#
# It can optionally export a work package details list with
# - title
# - attribute table
# - description with optional embedded images
#
# When exporting with embedded images then the memory consumption can quickly
# grow beyond limits. Therefore we create multiple smaller PDFs that we finally
# merge do one file.

require 'hexapdf'
require 'open3'

class WorkPackage::PDFExport::WorkPackageListToPdf < WorkPackage::Exports::QueryExporter
  include WorkPackage::PDFExport::Common
  include WorkPackage::PDFExport::Attachments
  include WorkPackage::PDFExport::OverviewTable
  include WorkPackage::PDFExport::WorkPackageDetail
  include WorkPackage::PDFExport::Page

  attr_accessor :pdf,
                :options

  def self.key
    :pdf
  end

  def initialize(object, options = {})
    super

    @page_count = 0
    @work_packages_per_batch = 100
    setup_page!
  end

  def export!
    file = render_work_packages query.results.work_packages
    success(file)
  rescue Prawn::Errors::CannotFit
    error(I18n.t(:error_pdf_export_too_many_columns))
  rescue StandardError => e
    Rails.logger.error { "Failed to generated PDF export: #{e} #{e.message}}." }
    error(I18n.t(:error_pdf_failed_to_export, error: e.message))
  end

  private

  def setup_page!
    self.pdf = get_pdf(current_language)

    configure_page_size!(with_descriptions? ? :portrait : :landscape)
  end

  def render_work_packages(work_packages, filename: "pdf_export")
    @id_wp_meta_map = build_meta_infos_map(work_packages)
    write_title!
    write_work_packages_overview! work_packages
    if should_be_batched?(work_packages)
      render_batched(work_packages, filename)
    else
      render_pdf(work_packages, filename)
    end
  end

  def render_batched(work_packages, filename)
    @batches_count = work_packages.length.fdiv(@work_packages_per_batch).ceil
    batch_files = []
    (1..@batches_count).each do |batch_index|
      batch_work_packages = work_packages.paginate(page: batch_index, per_page: @work_packages_per_batch)
      batch_files.push render_pdf(batch_work_packages, "pdf_batch_#{batch_index}.pdf")
      setup_page!
    end
    merge_batched_pdfs(batch_files, filename)
  end

  def merge_batched_pdfs(batch_files, filename)
    return batch_files[0] if batch_files.length == 1

    merged_pdf = Tempfile.new(filename)

    # TODO: Also possible, use the hexapdf cli that comes with the gem
    # Open3.capture2e("hexapdf", 'merge', '--force', *batch_files.map(&:path), merged_pdf.path)

    # TODO: All internal link annotions are not copied over on merging, is there a way to preserve them?
    target = HexaPDF::Document.new
    batch_files.each do |batch_file|
      pdf = HexaPDF::Document.open(batch_file.path)
      pdf.pages.each { |page| target.pages << target.import(page) }
    end
    target.write(merged_pdf.path, optimize: true)

    merged_pdf
  end

  def render_pdf(work_packages, filename)
    @resized_image_paths = []
    write_work_packages_details!(work_packages, @id_wp_meta_map) if with_descriptions?
    write_after_pages!
    file = Tempfile.new(filename)
    pdf.render_file(file.path)
    @page_count += pdf.page_count
    delete_all_resized_images
    file.close
    file
  end

  def write_after_pages!
    write_headers!
    write_footers!
  end

  def init_meta_infos_map_nodes(work_packages)
    infos_map = {}
    work_packages.each do |work_package|
      infos_map[work_package.id] = { level_path: [], level: 0, children: [] }
    end
    infos_map
  end

  def link_meta_infos_map_nodes(infos_map, work_packages)
    work_packages.reject { |wp| wp.parent_id.nil? }.each do |work_package|
      parent = infos_map[work_package.parent_id]
      infos_map[work_package.id][:parent] = parent
      parent[:children].push(infos_map[work_package.id]) if parent
    end
    infos_map
  end

  def fill_meta_infos_map_nodes(node, level_path)
    node[:level_path] = level_path
    index = 1
    node[:children].each do |sub|
      fill_meta_infos_map_nodes(sub, level_path + [index])
      index += 1
    end
  end

  def build_meta_infos_map(work_packages)
    # build a quick access map for the hierarchy tree
    infos_map = init_meta_infos_map_nodes work_packages
    # connect parent and children (only wp available in the query)
    infos_map = link_meta_infos_map_nodes infos_map, work_packages
    # recursive travers creating level index path e.g. [1, 2, 1] from root nodes
    root_nodes = infos_map.values.select { |node| node[:parent].nil? }
    fill_meta_infos_map_nodes({ children: root_nodes }, [])
    infos_map
  end

  def should_be_batched?(work_packages)
    with_descriptions? && with_attachments? && (work_packages.length > @work_packages_per_batch)
  end

  def project
    query.project
  end

  def title
    "#{heading}.pdf"
  end

  def heading
    title = query.new_record? ? I18n.t(:label_work_package_plural) : query.name

    if project
      "#{project} - #{title}"
    else
      title
    end
  end

end
