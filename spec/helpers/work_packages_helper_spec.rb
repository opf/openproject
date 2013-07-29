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

describe WorkPackagesHelper do
  describe :work_package_breadcrumb do
    it 'should provide a link to index as the first element and all ancestors as links' do
      index_link = double('work_package_index_link')
      ancestors_links = double('ancestors_links')

      helper.stub!(:ancestors_links).and_return([ancestors_links])
      helper.stub!(:work_package_index_link).and_return(index_link)

      @expectation = [index_link, ancestors_links]

      helper.should_receive(:breadcrumb_paths).with(*@expectation)

      helper.work_package_breadcrumb
    end
  end

  describe :ancestors_links do
    it 'should return a list of links for every ancestor' do
      ancestors = [mock('ancestor1', id: 1),
                   mock('ancestor2', id: 2)]

      controller.stub!(:ancestors).and_return(ancestors)

      ancestors.each_with_index do |ancestor, index|
        helper.ancestors_links[index].should have_selector("a[href='#{work_package_path(ancestor.id)}']", :text => "##{ancestor.id}")

      end
    end
  end

  describe :work_package_index_link do
    it "should return a link to issue_index (work_packages index later)" do
      helper.work_package_index_link.should have_selector("a[href='#{issues_path}']", :text => I18n.t(:label_issue_plural))
    end
  end

  describe :work_package_form_issue_category_attribute do
    let(:stub_project) { FactoryGirl.build_stubbed(:project) }
    let(:stub_work_package) { FactoryGirl.build_stubbed(:planning_element) }
    let(:stub_category) { FactoryGirl.build_stubbed(:issue_category) }
    let(:form) { double('form', :select => "").as_null_object }

    before do
      # set sensible defaults
      stub!(:authorize_for).and_return(false)
      stub_project.stub!(:issue_categories).and_return([stub_category])
    end

    it "should return nothing if the project has no categories assigned" do
      stub_project.stub!(:issue_categories).and_return([])

      work_package_form_issue_category_attribute(form, stub_work_package, :project => stub_project).should be_nil
    end

    it "should have a :category symbol as the attribute" do
      work_package_form_issue_category_attribute(form, stub_work_package, :project => stub_project).attribute.should == :category
    end

    it "should render a select with the project's issue category" do
      select = double('select')

      form.should_receive(:select).with(:category_id,
                                        [[stub_category.name, stub_category.id]],
                                        :include_blank => true).and_return(select)

      work_package_form_issue_category_attribute(form, stub_work_package, :project => stub_project).field.should == select
    end

    it "should add an additional remote link to create new categories if allowed" do
      remote = "remote"

      stub!(:authorize_for).and_return(true)

      should_receive(:prompt_to_remote).with(*([anything()] * 3), project_issue_categories_path(stub_project), anything()).and_return(remote)

      work_package_form_issue_category_attribute(form, stub_work_package, :project => stub_project).field.should include(remote)
    end
  end
end
