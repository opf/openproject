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

class Issues::AutoCompletesController < ApplicationController
  before_filter :find_project

  def issues
    @issues = []
    q = params[:q].to_s

    if q.present?
      query = (params[:scope] == "all" && Setting.cross_project_issue_relations?) ? Issue : @project.work_packages

      @issues |= query.visible.find_all_by_id(q.to_i) if q =~ /^\d+$/

      @issues |= query.visible.find(:all,
                                    :limit => 10,
                                    :order => "#{WorkPackage.table_name}.id ASC",
                                    :conditions => ["LOWER(#{WorkPackage.table_name}.subject) LIKE :q OR CAST(#{WorkPackage.table_name}.id AS CHAR(13)) LIKE :q", {:q => "%#{q.downcase}%" }])
    end

    render :layout => false
  end

  private

  def find_project
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
