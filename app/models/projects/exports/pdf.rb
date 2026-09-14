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

module Projects::Exports
  class PDF < QueryExporter
    include Exports::PDF::Common::Common
    include Exports::PDF::Common::Logo
    include Exports::PDF::Common::Attachments
    include Exports::PDF::Common::Markdown
    include Exports::PDF::Common::Macro
    include Exports::PDF::Components::Page
    include Exports::PDF::Components::Cover
    include Projects::Exports::PDFExport::TableOfContent
    include Projects::Exports::PDFExport::Report
    include Projects::Exports::PDFExport::InfoMap
    include Projects::Exports::PDFExport::Styles
    include Exports::PDF::Common::ProjectAttributes

    attr_accessor :pdf

    def initialize(object, options = {})
      super
      setup_page!
    end

    def setup_page!
      self.pdf = get_pdf
      configure_page_size!(:portrait)
      pdf.title = heading
    end

    def export!
      file = render_pdf(all_projects)
      success(file)
    rescue StandardError => e
      error(e)
    end

    def title
      build_pdf_filename(heading)
    end

    def heading
      query.name || I18n.t(:label_project_plural)
    end

    def footer_title
      heading
    end

    def cover_page_heading
      heading
    end

    def cover_page_dates
      nil
    end

    def cover_page_subheading
      User.current&.name
    end

    def cover_page_title
      @cover_page_title ||= Setting.app_title
    end

    def render_pdf(projects, filename: "pdf_export")
      @page_count = 0
      @id_project_meta_map, flat_list = build_meta_infos_map(projects)
      file = render_projects_report_pdf(flat_list, filename)
      if wants_total_page_nrs?
        @total_page_nr = @page_count
        @page_count = 0
        setup_page! # clear current pdf
        file = render_projects_report_pdf(flat_list, filename)
      end
      file
    end

    def wants_total_page_nrs?
      true
    end

    def with_cover?
      true
    end

    def with_images?
      true
    end

    def hide_empty_attributes?
      true
    end

    def render_projects_report_pdf(flat_list, filename)
      render_projects_report(flat_list)
      file = Tempfile.new(filename)
      pdf.render_file(file.path)
      @page_count += pdf.page_count
      file.close
      file
    ensure
      delete_all_resized_images
    end

    def write_after_pages!
      write_headers!
      write_footers!
    end

    def render_projects_report(flat_list)
      write_cover_page! if with_cover?
      if flat_list.size > 1
        render_toc(flat_list, @id_project_meta_map)
      elsif !flat_list.empty?
        @id_project_meta_map[flat_list[0].id][:level_path] = []
      end
      render_report(flat_list, @id_project_meta_map)
      write_after_pages!
    end
  end
end
