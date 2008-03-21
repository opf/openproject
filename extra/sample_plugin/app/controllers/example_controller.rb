# Sample plugin controller
class ExampleController < ApplicationController
  unloadable
  
  layout 'base'  
  before_filter :find_project, :authorize
    
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
