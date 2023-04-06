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

class WorkPackage::PDFExport::WorkPackageToPdf < Exports::Exporter
  include WorkPackage::PDFExport::Common
  include WorkPackage::PDFExport::Attachments
  include WorkPackage::PDFExport::WorkPackageDetail
  include WorkPackage::PDFExport::Page

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
  end

  private

  def setup_page!
    self.pdf = get_pdf(current_language)
    @page_count = 0
    configure_page_size!(:portrait)
  end

  def render_work_package
    write_title!
    write_work_package_detail_content!(work_package)
    write_history!
    write_changesets! if show_changesets?
    write_headers!
    write_footers!
  end

  def show_changesets?
    work_package.changesets.any? &&
      User.current.allowed_to?(:view_changesets, work_package.project)
  end

  def heading
    "#{work_package.project} - ##{work_package.type} #{work_package.id}"
  end

  def title
    "#{heading}.pdf"
  end

  def write_history!
    write_field_label! I18n.t(:label_history)
    work_package.journals.includes(:user).order("#{Journal.table_name}.created_at ASC").each do |journal|
      next if journal.initial?

      write_history_item! journal
    end
  end

  def write_history_item!(journal)
    write_history_item_headline! journal
    write_history_item_content! journal
  end

  def write_history_item_headline!(journal)
    headline = "#{format_time(journal.created_at)} - #{journal.user.name}"
    with_margin(headline_margins_style) do
      pdf.formatted_text([headline_style.merge({ text: headline })])
    end
  end

  def write_history_item_content!(journal)
    with_margin(item_margins_style) do
      journal.details.each do |detail|
        text = journal.render_detail(detail, html: true, only_path: false)
        write_markdown! work_package, "* #{text}"
      end
      if journal.notes?
        text = journal.notes.to_s
        write_markdown! work_package, text
      end
    end
  end

  def write_changesets!
    write_field_label!(I18n.t(:label_associated_revisions))
    work_package.changesets.each do |changeset|
      write_changeset_item! changeset
    end
  end

  def write_changeset_item!(changeset)
    write_changeset_item_headline! changeset
    write_changeset_item_content! changeset
  end

  def write_changeset_item_headline!(changeset)
    headline = "#{format_time(changeset.committed_on)} - #{changeset.author}"
    with_margin(headline_margins_style) do
      pdf.formatted_text([headline_style.merge({ text: headline })])
    end
  end

  def write_changeset_item_content!(changeset)
    if changeset.comments.present?
      with_margin(item_margins_style) do
        pdf.formatted_text([headline_style.merge({ text: changeset.comments.to_s })])
      end
    end
  end

  def headline_margins_style
    { margin_top: 4, margin_bottom: 4 }
  end

  def headline_style
    { size: 9, styles: [:bold] }
  end

  def item_margins_style
    { margin_left: 10 }
  end

  def item_style
    { size: 9, styles: [:italic] }
  end
end
