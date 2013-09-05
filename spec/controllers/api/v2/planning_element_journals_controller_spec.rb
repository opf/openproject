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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::PlanningElementJournalsController do
  let(:project) { FactoryGirl.create(:project, :is_public => false) }

  describe 'index.xml' do
    def fetch
      planning_element = FactoryGirl.create(:work_package,
                                            :project_id => project.id)

      get 'index', :project_id          => project.identifier,
                   :planning_element_id => planning_element.id,
                   :format              => 'xml'
    end
    let(:permission) { :view_planning_elements }

    it_should_behave_like "a controller action which needs project permissions"
  end
end

