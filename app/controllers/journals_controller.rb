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

require 'diff'

class JournalsController < ApplicationController
  before_filter :find_journal, except: [:index]
  before_filter :find_optional_project, only: [:index]
  before_filter :authorize, only: [:edit, :update, :preview, :diff]
  accept_key_auth :index
  menu_item :issues

  include QueriesHelper
  include SortHelper

  def index
    retrieve_query
    sort_init 'id', 'desc'
    sort_update(@query.sortable_columns)

    if @query.valid?
      @journals = @query.work_package_journals(order: "#{Journal.table_name}.created_at DESC",
                                               limit: 25)
    end

    title = (@project ? @project.name : Setting.app_title) + ': ' + (@query.new_record? ? l(:label_changes_details) : @query.name)

    respond_to do |format|
      format.atom do
        render layout: false,
               content_type: 'application/atom+xml',
               locals: { title: title,
                         journals: @journals }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def edit
    (render_403; return false) unless @journal.editable_by?(User.current)
    respond_to do |format|
      format.html {
        # TODO: implement non-JS journal update
        render nothing: true
      }
      format.js
    end
  end

  def update
    @journal.update_attribute(:notes, params[:notes]) if params[:notes]
    @journal.destroy if @journal.details.empty? && @journal.notes.blank?
    call_hook(:controller_journals_edit_post,  journal: @journal, params: params)
    respond_to do |format|
      format.html {
        redirect_to controller: "/#{@journal.journable.class.name.pluralize.downcase}",
                    action: 'show', id: @journal.journable_id
      }
      format.js { render action: 'update' }
    end
  end

  def diff
    if valid_diff?
      field = params[:field].parameterize.underscore.to_sym
      from = @journal.changed_data[field][0]
      to = @journal.changed_data[field][1]

      @diff = Redmine::Helpers::Diff.new(to, from)
      @journable = @journal.journable
      respond_to do |format|
        format.html {}
        format.js { render partial: 'diff', locals: { diff: @diff } }
      end
    else
      render_404
    end
  end

  def preview
    @journal.notes = params[:notes]

    respond_to do |format|
      format.any(:html, :js) {
        render locals: { journal: @journal },
               layout: false
      }
    end
  end

  private

  def find_journal
    @journal = Journal.find(params[:id])
    @project = @journal.journable.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Is this a valid field for diff'ing?
  def valid_field?(field)
    field.to_s.strip == 'description'
  end

  def default_breadcrumb
    I18n.t(:label_journal_diff)
  end

  def valid_diff?
    return false unless valid_field?(params[:field])
    @journal.journable.class == WorkPackage
  end
end
