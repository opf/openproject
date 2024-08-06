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

class JournalsController < ApplicationController
  before_action :load_and_authorize_in_optional_project, only: [:index]
  before_action :find_journal,
                :ensure_permitted,
                only: [:diff]
  authorization_checked! :diff

  accept_key_auth :index
  menu_item :issues

  include QueriesHelper
  include SortHelper

  def index
    @query = retrieve_query(@project)
    sort_init "id", "desc"
    sort_update(@query.sortable_key_by_column_name)

    if @query.valid?
      @journals = @query.work_package_journals(order: "#{Journal.table_name}.created_at DESC",
                                               limit: 25)
    end

    respond_to do |format|
      format.atom do
        render layout: false,
               content_type: "application/atom+xml",
               locals: { title: journals_index_title,
                         journals: @journals }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def diff
    return render_404 unless valid_field_for_diffing?

    unless @journal.details[field_param] in [from, to]
      return render_400 message: I18n.t(:error_journal_attribute_not_present, attribute: field_param)
    end

    @activity_page = params["activity_page"]
    @diff = Redmine::Helpers::Diff.new(to, from)

    respond_to do |format|
      format.html
      format.js do
        render partial: "diff", locals: { diff: @diff }
      end
    end
  end

  private

  def find_journal
    @journal = Journal.find(params[:id])
    @journable = @journal.journable
    @project = @journable.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def ensure_permitted
    permission = case @journal.journable_type
                 when "WorkPackage" then :view_work_packages
                 when "Project" then :view_project
                 when "Meeting" then :view_meetings
                 end

    do_authorize(permission)
  rescue Authorization::UnknownPermissionError
    deny_access
  end

  def field_param
    @field_param ||= params[:field].parameterize.underscore
  end

  def valid_field_for_diffing?
    case field_param
    when "description",
         "status_explanation",
         /\Aagenda_items_\d+_notes\z/
      true
    when /\Acustom_fields_(?<id>\d+)\z/
      ::CustomField.exists?(id: Regexp.last_match[:id], field_format: "text")
    end
  end

  def journals_index_title
    subject = @project ? @project.name : Setting.app_title
    query_name = @query.new_record? ? I18n.t(:label_changes_details) : @query.name
    "#{subject}: #{query_name}"
  end
end
