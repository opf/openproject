#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

class WorkPackageBoxesController < WorkPackagesController
  helper :rb_common

  def show
    return redirect_to work_package_path(params[:id]) unless request.xhr?

    load_journals
    @changesets = @work_package.changesets.visible.all
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?
    @relations = @work_package.relations.select { |r| r.other_work_package(@work_package) && r.other_work_package(@work_package).visible? }
    @allowed_statuses = WorkPackages::UpdateContract.new(work_package, User.current).assignable_statuses
    @edit_allowed = User.current.allowed_to?(:edit_work_packages, @project)
    @priorities = IssuePriority.all
    @time_entry = TimeEntry.new

    respond_to do |format|
      format.js   { render partial: 'show' }
    end
  end

  def edit
    return redirect_to edit_work_package_path(params[:id]) unless request.xhr?

    update_work_package_from_params
    load_journals
    @journal = @work_package.last_journal

    respond_to do |format|
      format.js   { render partial: 'edit' }
    end
  end

  def update
    update_work_package_from_params

    if @work_package.save_work_package_with_child_records(params, @time_entry)
      @work_package.reload
      load_journals
      respond_to do |format|
        format.js   { render partial: 'show' }
      end
    else
      @journal = @work_package.last_journal
      respond_to do |format|
        format.js { render partial: 'edit' }
      end
    end
  end

  private

  def load_journals
    @journals = @work_package.journals.includes(:user).order("#{Journal.table_name}.created_at ASC")
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
  end
end
