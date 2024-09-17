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

module Versions
  class RowComponent < ::RowComponent
    # Overriding cell's method to set the project instance variable.
    # A lot of helpers rely on the existence of it.
    def setup!(model, options)
      instance_variable_set(:@project, options[:table].project) if options[:table].project

      super
    end

    def version
      model
    end

    delegate :project, to: :version

    def row_css_class
      shared = "shared" if version.project != table.project

      ["version", shared].compact.join(" ")
    end

    def name
      helpers.link_to_version version, {}, project: version.project
    end

    def start_date
      helpers.format_date(version.start_date)
    end

    def effective_date
      helpers.format_date(version.effective_date)
    end

    def description
      h(version.description)
    end

    def status
      t("version_status_#{version.status}")
    end

    def sharing
      helpers.format_version_sharing(version.sharing)
    end

    def wiki_page
      return "" if wiki_page_title.blank? || version.project.wiki.nil?

      helpers.link_to_if_authorized(wiki_page_title,
                                    controller: "/wiki",
                                    action: "show",
                                    project_id: version.project,
                                    id: wiki_page_title) || h(wiki_page_title)
    end

    def button_links
      [edit_link, delete_link, backlogs_edit_link].compact
    end

    private

    def wiki_page_title
      version.wiki_page_title
    end

    def edit_link
      return unless version.project == table.project

      helpers.link_to_if_authorized "",
                                    { controller: "/versions", action: "edit", id: version },
                                    class: "icon icon-edit",
                                    title: t(:button_edit)
    end

    def delete_link
      return unless version.project == table.project

      helpers.link_to_if_authorized "",
                                    { controller: "/versions", action: "destroy", id: version },
                                    data: { confirm: t(:text_are_you_sure) },
                                    method: :delete,
                                    class: "icon icon-delete",
                                    title: t(:button_delete)
    end

    def column_css_class(column)
      if column == :name
        super.to_s + name_css_class
      else
        super
      end
    end

    def name_css_class
      classes = " #{version.status}"

      if version.project != table.project
        classes += " icon-context icon-link"
      end

      classes
    end
  end
end
