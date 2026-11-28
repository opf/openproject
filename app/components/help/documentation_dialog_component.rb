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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Help
  class DocumentationDialogComponent < ApplicationComponent
    DIALOG_ID = "contextual-documentation-dialog"
    FRAME_ID = "contextual-documentation-article"

    def self.dialog_id(context)
      "#{DIALOG_ID}-#{context}"
    end

    def self.frame_id(context)
      "#{FRAME_ID}-#{context}"
    end

    def initialize(context: "life_cycle", show_button: false)
      super()
      @context = context
      @show_button = show_button
      @articles = DocumentationArticle.for_context(context)
    end

    def initial_article_path
      documentation_article_help_path(article_id: @articles.first.id, context: @context)
    end

    def index_path
      documentation_article_help_path(article_id: "index", context: @context)
    end

    def trigger_label
      t("contextual_help.#{@context}.open")
    end

    def trigger_selector
      @context == "life_cycle" ? "project-life-cycle-contextual-help" : "project-initiation-contextual-help"
    end
  end
end
