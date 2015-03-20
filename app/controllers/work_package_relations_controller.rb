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

class WorkPackageRelationsController < ApplicationController
  before_filter :find_work_package, :find_project_from_association, :authorize

  def create
    @relation = @work_package.new_relation.tap do |r|
      r.to = WorkPackage.visible.find_by_id(params[:relation][:to_id].match(/\d+/).to_s)
      r.relation_type = params[:relation][:relation_type]
      r.delay = params[:relation][:delay]
    end

    @relation.save

    respond_to do |format|
      format.html { redirect_to work_package_path(@work_package) }
      format.js {
        render action: 'create', locals: { work_package: work_package,
                                           relation: @relation }
      }
    end
  end

  def destroy
    @relation = @work_package.relation(params[:id])

    @relation.destroy

    respond_to do |format|
      format.html { redirect_to work_package_path(@work_package) }
      format.js {}
    end
  end

  def work_package
    @work_package
  end

  private

  def find_work_package
    @work_package = @object = WorkPackage.find(params[:work_package_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
