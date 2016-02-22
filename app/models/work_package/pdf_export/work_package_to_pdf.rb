#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackage::PdfExport::WorkPackageToPdf
  include Redmine::I18n
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper
  include CustomFieldsHelper
  include WorkPackage::PdfExport::ToPdfHelper

  attr_accessor :work_package,
                :pdf

  def initialize(work_package)
    self.work_package = work_package

    self.pdf = get_pdf(current_language)
  end

  def to_pdf
    pdf.SetTitle("#{work_package.project} - ##{work_package.type} #{work_package.id}")
    pdf.alias_nb_pages
    pdf.footer_date = format_date(Date.today)
    pdf.AddPage

    pdf.SetFontStyle('B', 11)
    pdf.RDMMultiCell(190, 5, "#{work_package.project} - #{work_package.type} # #{work_package.id}: #{work_package.subject}")
    pdf.Ln

    y0 = pdf.GetY

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:status) + ':', 'LT')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, work_package.status.to_s, 'RT')
    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:priority) + ':', 'LT')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, work_package.priority.to_s, 'RT')
    pdf.Ln

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:author) + ':', 'L')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, work_package.author.to_s, 'R')
    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:category) + ':', 'L')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, work_package.category.to_s, 'R')
    pdf.Ln

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:created_at) + ':', 'L')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, format_date(work_package.created_at), 'R')
    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:assigned_to) + ':', 'L')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, work_package.assigned_to.to_s, 'R')
    pdf.Ln

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:updated_at) + ':', 'LB')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, format_date(work_package.updated_at), 'RB')
    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:due_date) + ':', 'LB')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, format_date(work_package.due_date), 'RB')
    pdf.Ln

    for custom_value in work_package.custom_field_values
      pdf.SetFontStyle('B', 9)
      pdf.RDMCell(35, 5, custom_value.custom_field.name + ':', 'L')
      pdf.SetFontStyle('', 9)
      pdf.RDMMultiCell(155, 5, (show_value custom_value), 'R')
    end

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:description) + ':')
    pdf.SetFontStyle('', 9)
    pdf.RDMMultiCell(155, 5, work_package.description.to_s, 'BR')

    pdf.Line(pdf.GetX, y0, pdf.GetX, pdf.GetY)
    pdf.Line(pdf.GetX, pdf.GetY, pdf.GetX + 190, pdf.GetY)
    pdf.Ln

    if work_package.changesets.any? && User.current.allowed_to?(:view_changesets, work_package.project)
      pdf.SetFontStyle('B', 9)
      pdf.RDMCell(190, 5, l(:label_associated_revisions), 'B')
      pdf.Ln
      for changeset in work_package.changesets
        pdf.SetFontStyle('B', 8)
        pdf.RDMCell(190, 5, format_time(changeset.committed_on) + ' - ' + changeset.author.to_s)
        pdf.Ln
        unless changeset.comments.blank?
          pdf.SetFontStyle('', 8)
          pdf.RDMMultiCell(190, 5, changeset.comments.to_s)
        end
        pdf.Ln
      end
    end

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(190, 5, l(:label_history), 'B')
    pdf.Ln
    for journal in work_package.journals.includes(:user).order("#{Journal.table_name}.created_at ASC")
      next if journal.initial?
      pdf.SetFontStyle('B', 8)
      pdf.RDMCell(190, 5, format_time(journal.created_at) + ' - ' + journal.user.name)
      pdf.Ln
      pdf.SetFontStyle('I', 8)
      for detail in journal.details
        pdf.RDMMultiCell(190, 5, '- ' + journal.render_detail(detail, no_html: true, only_path: false))
        pdf.Ln
      end
      if journal.notes?
        pdf.Ln unless journal.details.empty?
        pdf.SetFontStyle('', 8)
        pdf.RDMMultiCell(190, 5, journal.notes.to_s)
      end
      pdf.Ln
    end

    if work_package.attachments.any?
      pdf.SetFontStyle('B', 9)
      pdf.RDMCell(190, 5, l(:label_attachment_plural), 'B')
      pdf.Ln
      for attachment in work_package.attachments
        pdf.SetFontStyle('', 8)
        pdf.RDMCell(80, 5, attachment.filename)
        pdf.RDMCell(20, 5, number_to_human_size(attachment.filesize), 0, 0, 'R')
        pdf.RDMCell(25, 5, format_date(attachment.created_on), 0, 0, 'R')
        pdf.RDMCell(65, 5, attachment.author.name, 0, 0, 'R')
        pdf.Ln
      end
    end
    pdf.Output
  end
end
