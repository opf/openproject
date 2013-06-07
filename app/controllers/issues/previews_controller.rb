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

class Issues::PreviewsController < ApplicationController
  before_filter :find_model_object_and_project,
                :authorize

  model_object Issue

  def create
    if @issue
      @attachements = @issue.attachments
      @description = params[:issue] && params[:issue][:description]
      if @description && @description.gsub(/(\r?\n|\n\r?)/, "\n") == @issue.description.to_s.gsub(/(\r?\n|\n\r?)/, "\n")
        @description = nil
      end
      @notes = params[:notes]
    else
      @description = (params[:issue] ? params[:issue][:description] : nil)
    end
    render :layout => false
  end
end
