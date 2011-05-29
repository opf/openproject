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

# Sample plugin controller
class ExampleController < ApplicationController
  unloadable
  
  layout 'base'  
  before_filter :find_project, :authorize
  menu_item :sample_plugin
    
  def say_hello
    @value = Setting.plugin_sample_plugin['sample_setting']
  end

  def say_goodbye
  end
  
private
  def find_project   
    @project=Project.find(params[:id])
  end
end
