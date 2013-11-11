require 'spec_helper'

describe RbServerVariablesController do
  describe "routing" do
    it { get('/projects/project_42/server_variables.js').should route_to(:controller => 'rb_server_variables',
                                                                         :action => 'show',
                                                                         :format => 'js',
                                                                         :project_id => 'project_42') }
  end
end
