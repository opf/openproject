require 'spec_helper'

describe DocumentsController do
  describe "routing" do
    it { get('/projects/567/documents').should route_to(:controller => 'documents',
                                                        :action => 'index',
                                                        :project_id => '567' ) }

    it { get('/projects/567/documents/new').should route_to(:controller => 'documents',
                                                            :action => 'new',
                                                            :project_id => '567' ) }

    it { get('/documents/22').should route_to(:controller => 'documents',
                                              :action => 'show',
                                              :id => '22') }

    it { get('/documents/22/edit').should route_to(:controller => 'documents',
                                                   :action => 'edit',
                                                   :id => '22') }

    it { post('/projects/567/documents').should route_to(:controller => 'documents',
                                                         :action => 'create',
                                                         :project_id => '567') }

    it { put('/documents/567').should route_to(:controller => 'documents',
                                               :action => 'update',
                                               :id => '567') }

    it { delete('/documents/567').should route_to(:controller => 'documents',
                                                  :action => 'destroy',
                                                  :id => '567') }
  end
end
