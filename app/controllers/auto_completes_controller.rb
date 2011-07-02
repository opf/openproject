#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class AutoCompletesController < ApplicationController
  before_filter :find_project

  def issues
    @issues = []
    q = params[:q].to_s

    if q.present?
      query = (params[:scope] == "all" && Setting.cross_project_issue_relations?) ? Issue : @project.issues

      @issues |= query.visible.find_all_by_id(q.to_i) if q =~ /^\d+$/

      @issues |= query.visible.find(:all,
                                    :limit => 10,
                                    :order => "#{Issue.table_name}.id ASC",
                                    :conditions => ["LOWER(#{Issue.table_name}.subject) LIKE :q OR CAST(#{Issue.table_name}.id AS CHAR(13)) LIKE :q", {:q => "%#{q.downcase}%" }])
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
