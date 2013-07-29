#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackageRelationsController < ApplicationController
  before_filter :find_work_package, :find_project_from_association, :authorize

  def create
    @relation = @work_package.new_relation.tap do |r|
      r.issue_to = WorkPackage.visible.find_by_id(params[:relation][:issue_to_id].match(/\d+/).to_s)
      r.relation_type = params[:relation][:relation_type]
      r.delay = params[:relation][:delay]
    end

    @relation.save

    respond_to do |format|
      format.html { redirect_to work_package_path(@work_package) }
      format.js { render :action => 'create', :locals => { :work_package => work_package,
                                                            :relation => @relation } }
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
