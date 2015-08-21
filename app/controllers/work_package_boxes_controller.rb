#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

class WorkPackageBoxesController < WorkPackagesController
  helper :rb_common

  def show
    return redirect_to work_package_path(params[:id]) unless request.xhr?

    load_journals
    @changesets = @work_package.changesets.visible.all
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?
    @relations = @work_package.relations.select { |r| r.other_work_package(@work_package) && r.other_work_package(@work_package).visible? }
    @allowed_statuses = @work_package.new_statuses_allowed_to(User.current)
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
    @journal = @work_package.current_journal

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
      @journal = @work_package.current_journal
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
