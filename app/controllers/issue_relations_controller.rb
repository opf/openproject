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

class IssueRelationsController < ApplicationController
  before_filter :find_issue, :find_project_from_association, :authorize

  def create
    @relation = @issue.new_relation.tap do |r|
      r.issue_to = Issue.visible.find_by_id(params[:relation][:issue_to_id].match(/\d+/).to_s)
      r.relation_type = params[:relation][:relation_type]
      r.delay = params[:relation][:delay]
    end

    @relation.save

    respond_to do |format|
      format.html { redirect_to issue_path(@issue) }
      format.js {}
    end
  end

  def destroy
    @relation = @issue.relation(params[:id])

    @relation.destroy

    respond_to do |format|
      format.html { redirect_to issue_path(@issue) }
      format.js {}
    end
  end

private
  def find_issue
    @issue = @object = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
