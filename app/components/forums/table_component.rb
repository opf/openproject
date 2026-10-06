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

module Forums
  class TableComponent < OpPrimer::BorderBoxTableComponent
    columns :name, :topics_count, :messages_count, :last_message
    main_column :name, :last_message
    mobile_columns :name

    options :project

    def headers
      [
        [:name, { caption: Forum.model_name.human }],
        [:topics_count, { caption: I18n.t(:label_topic_plural) }],
        [:messages_count, { caption: I18n.t(:label_message_plural) }],
        [:last_message, { caption: I18n.t(:label_message_last) }]
      ]
    end

    def manageable?
      User.current.allowed_in_project?(:manage_forums, project)
    end

    def has_actions? = manageable?

    def mobile_title = I18n.t(:label_forum_plural)

    def container_id = "forums-table"

    def blank_icon = :"comment-discussion"

    def blank_title = I18n.t("forums.index.no_results_title_text")

    def blank_description = nil
  end
end
