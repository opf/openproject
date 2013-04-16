require 'spec_helper'

describe IssueBoxesController do
  describe "routing" do
    it { get('/issue_boxes/42/edit').should route_to(:controller => 'issue_boxes',
                                                     :action => 'edit',
                                                     :id => '42') }
    it { get('/issue_boxes/42').should route_to(:controller => 'issue_boxes',
                                                     :action => 'show',
                                                     :id => '42') }
    it { put('/issue_boxes/42').should route_to(:controller => 'issue_boxes',
                                                     :action => 'update',
                                                     :id => '42') }
  end
end