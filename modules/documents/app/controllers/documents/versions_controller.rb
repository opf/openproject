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

module Documents
  class VersionsController < ApplicationController
    before_action :find_document
    before_action :authorize

    def index
      @max_version = @document.journals.maximum(:version).to_i
      journals_scope = @document.journals
        .preload(:user, :data)
        .reorder(version: :desc)

      scroll_to_id = params[:scroll_to].presence&.to_i
      @scroll_to_id = scroll_to_id

      if scroll_to_id
        # Load enough items so the target journal is included (journals are ordered desc by version)
        target_journal = @document.journals.find_by(id: scroll_to_id)
        if target_journal
          target_offset = @document.journals.where("version > ?", target_journal.version).count
          load_count = [target_offset + 1, 20].max
        else
          load_count = 20
        end
        @journals = journals_scope.limit(load_count + 1)
        @has_more = @journals.size > load_count
        @journals = @journals.first(load_count)
        @next_offset = load_count
      else
        offset = [params[:offset].to_i, 0].max
        per_page = offset == 0 ? 20 : 50
        @journals = journals_scope.offset(offset).limit(per_page + 1)
        @has_more = @journals.size > per_page
        @journals = @journals.first(per_page)
        @next_offset = offset + per_page
      end

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    private

    def find_document
      @document = Document.visible.find(params[:document_id])
      @project = @document.project
    end

    def default_breadcrumb
      @document.title
    end
  end
end
