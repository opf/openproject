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

describe '/api/v1/issues/index', :type => :api do
  let(:work_package) { FactoryGirl.build(:work_package, :done_ratio => 50) }
  let(:work_packages) do
    packages = [work_package]
    packages.stub(:total_entries).and_return(1)
    packages.stub(:offset).and_return(0)
    packages.stub(:per_page).and_return(1)
    packages
  end

  before do
    params[:format] = 'xml'

    assign(:issues, work_packages)
  end

  context 'with done_ratio enabled' do
    before { render }

    it 'should include a done_ratio' do
      response.should have_selector('issue done_ratio')
      response.should have_xpath("//issue/done_ratio[.='50']")
    end
  end

  context 'with done_ratio disabled' do
    before do
      Setting.stub(:issue_done_ratio).and_return('disabled')
      render
    end

    it 'should NOT include a done_ratio' do
      response.should_not have_selector('issue done_ratio')
    end
  end
end
