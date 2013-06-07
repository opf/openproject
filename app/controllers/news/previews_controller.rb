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

class News::PreviewsController < ApplicationController
  before_filter :find_model_object_and_project

  model_object News

  def create
    @text = news_params[:description]
    render :partial => 'common/preview'
  end

private

  def news_params
    params.fetch(:news, {})
  end
end
