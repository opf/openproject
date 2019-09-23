#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'diff'

class JournalsController < ApplicationController
  before_action :find_journal, except: [:index]
  before_action :find_optional_project, only: [:index]
  before_action :authorize, only: [:diff]
  accept_key_auth :index
  menu_item :issues

  include QueriesHelper
  include SortHelper

  def index
    retrieve_query
    sort_init 'id', 'desc'
    sort_update(@query.sortable_key_by_column_name)

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

  def diff
    journal = Journal::AggregatedJournal.for_journal(@journal)
    field = params[:field].parameterize.underscore.to_sym

    unless valid_diff?
      return render_404
    end

    unless journal.details[field].is_a?(Array)
      return render_400 message: I18n.t(:error_journal_attribute_not_present, attribute: field)
    end

    from = journal.details[field][0]
    to = journal.details[field][1]

    @diff = Redmine::Helpers::Diff.new(to, from)
    @journable = journal.journable
    respond_to do |format|
      format.html
      format.js do
        render partial: 'diff', locals: { diff: @diff }
      end
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

  def valid_diff?
    return false unless valid_field?(params[:field])
    @journal.journable.class == WorkPackage
  end
end
