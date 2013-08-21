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

require 'spec_helper'

describe JournalsController do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:role) { FactoryGirl.create(:role, :permissions => [:view_work_package]) }
  let(:member) { FactoryGirl.build(:member, :project => project,
                                            :roles => [role],
                                            :principal => user) }
  let(:issue) { FactoryGirl.build(:issue, :type => project.types.first,
                                          :author => user,
                                          :project => project,
                                          :description => '') }

  describe "GET diff" do
    render_views

    before do
      issue.update_attribute :description, 'description'
      params = { :id => issue.journals.last.id.to_s, :field => :description, :format => 'js' }

      get :diff, params
    end

    it { response.should be_success }
    it { response.body.strip.should == "<div class=\"text-diff\">\n  <ins class=\"diffmod\">description</ins>\n</div>" }
  end
end
