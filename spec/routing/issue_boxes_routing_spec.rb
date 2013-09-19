require 'spec_helper'

describe WorkPackageBoxesController do
  describe "routing" do
    it { get('/work_package_boxes/42/edit').should route_to(:controller => 'work_package_boxes',
                                                     :action => 'edit',
                                                     :id => '42') }
    it { get('/work_package_boxes/42').should route_to(:controller => 'work_package_boxes',
                                                     :action => 'show',
                                                     :id => '42') }
    it { put('/work_package_boxes/42').should route_to(:controller => 'work_package_boxes',
                                                     :action => 'update',
                                                     :id => '42') }
  end
end
