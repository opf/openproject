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
  let(:stub_work_package) { FactoryGirl.build_stubbed(:planning_element) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project) }
  let(:stub_type) { FactoryGirl.build_stubbed(:type) }
  let(:form) { double('form', :select => "").as_null_object }
  let(:stub_user) { FactoryGirl.build_stubbed(:user) }

  def inside_form &block
    ret = ''

    form_for(stub_work_package, :as => 'work_package', :url => work_package_path(stub_work_package)) do |f|
      ret = yield f
    end

    ret
  end

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

  describe :link_to_work_package do
    let(:open_status) { FactoryGirl.build_stubbed(:issue_status, :is_closed => false) }
    let(:closed_status) { FactoryGirl.build_stubbed(:issue_status, :is_closed => true) }

    before do
      stub_work_package.status = open_status
    end

    describe "without parameters" do
      it 'should return a link to the work package with the id as the text' do
        link_text = Regexp.new("^##{stub_work_package.id}$")
        helper.link_to_work_package(stub_work_package).should have_selector("a[href='#{work_package_path(stub_work_package)}']", :text => link_text)
      end

      it 'should return a link to the work package with type and id as the text if type is set' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^#{stub_type.name} ##{stub_work_package.id}$")
        helper.link_to_work_package(stub_work_package).should have_selector("a[href='#{work_package_path(stub_work_package)}']", :text => link_text)
      end

      it 'should additionally return the subject' do
        text = Regexp.new("#{stub_work_package.subject}$")
        helper.link_to_work_package(stub_work_package).should have_text(text)
      end

      it 'should prepend an invisible closed information if the work package is closed' do
        stub_work_package.status = closed_status

        helper.link_to_work_package(stub_work_package).should have_selector("a span.hidden-for-sighted", :text => "closed")
      end
    end

    describe "with the all_link option provided" do
      it 'should return a link to the work package with the type, id, and subject as the text' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^#{stub_type.to_s} ##{stub_work_package.id}: #{stub_work_package.subject}$")
        helper.link_to_work_package(stub_work_package, :all_link => true).should have_selector("a[href='#{work_package_path(stub_work_package)}']", :text => link_text)
      end
    end

    describe "when truncating" do
      it 'should truncate the subject if the subject is longer than the specified amount' do
        stub_work_package.subject = "12345678"

        text = Regexp.new("1234...$")
        helper.link_to_work_package(stub_work_package, :truncate => 7).should have_text(text)
      end

      it 'should not truncate the subject if the subject is shorter than the specified amount' do
        stub_work_package.subject = "1234567"

        text = Regexp.new("1234567$")
        helper.link_to_work_package(stub_work_package, :truncate => 7).should have_text(text)
      end
    end

    describe "when omitting the subject" do
      it 'should omit the subject' do
        helper.link_to_work_package(stub_work_package, :subject => false).should_not have_text(stub_work_package.subject)
      end
    end

    describe "when omitting the type" do
      it 'should omit the type' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^##{stub_work_package.id}$")
        helper.link_to_work_package(stub_work_package, :type => false).should have_selector("a[href='#{work_package_path(stub_work_package)}']", :text => link_text)
      end
    end

    describe "with a project" do
      let(:text) { Regexp.new("^#{stub_project.name} -") }

      before do
        stub_work_package.project = stub_project
      end

      it 'should prepend the project if parameter set to true' do
        helper.link_to_work_package(stub_work_package, :project => true).should have_text(text)
      end

      it 'should not have the project name if the parameter is missing/false' do
        helper.link_to_work_package(stub_work_package).should_not have_text(text)
      end
    end

    describe "when only wanting the id" do
      it 'should return a link with the id as text only even if the work package has a type' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^##{stub_work_package.id}$")
        helper.link_to_work_package(stub_work_package, :id_only => true).should have_selector("a[href='#{work_package_path(stub_work_package)}']", :text => link_text)
      end

      it 'should not have the subject as text' do
        helper.link_to_work_package(stub_work_package, :id_only => true).should_not have_text(stub_work_package.subject)
      end
    end

    describe "when only wanting the subject" do
      it 'should return a link with the subject as text' do
        link_text = Regexp.new("^#{stub_work_package.subject}$")
        helper.link_to_work_package(stub_work_package, :subject_only => true).should have_selector("a[href='#{work_package_path(stub_work_package)}']", :text => link_text)
      end
    end
  end

  describe :work_package_index_link do
    it "should return a link to issue_index (work_packages index later)" do
      helper.work_package_index_link.should have_selector("a[href='#{issues_path}']", :text => I18n.t(:label_work_package_plural))
    end
  end

  describe :work_package_show_spent_time_attribute do
    it "should show a spent time link pointing to the time entries of the work package" do
      stub_work_package.stub(:spent_hours).and_return(5.0)

      field = helper.work_package_show_spent_time_attribute(stub_work_package).field

      expected_href = issue_time_entries_path(stub_work_package)

      field.should have_css(".spent-time a[@href='#{ expected_href }']", :text => '5.0')
    end

    it "should show a '-' if spent time is 0" do
      stub_work_package.stub(:spent_hours).and_return(0.0)

      field = helper.work_package_show_spent_time_attribute(stub_work_package).field

      field.should have_css(".spent-time", :text => '-')
    end
  end

  describe :work_package_form_issue_category_attribute do
    let(:stub_project) { FactoryGirl.build_stubbed(:project) }
    let(:stub_category) { FactoryGirl.build_stubbed(:issue_category) }

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

  describe :work_package_css_classes do
    let(:statuses) { (1..5).map{ |i| FactoryGirl.build_stubbed(:issue_status)}}
    let(:priority) { FactoryGirl.build_stubbed :priority, is_default: true }
    let(:status) { statuses[0] }
    let(:stub_work_package) { FactoryGirl.build_stubbed(:planning_element,
                                                        :status => status,
                                                        :priority => priority) }

    it "should always have the work_package class" do
      helper.work_package_css_classes(stub_work_package).should include("work_package")
    end

    it "should return the position of the work_package's status" do
      status = double('status', :is_closed? => false)

      stub_work_package.stub!(:status).and_return(status)
      status.stub!(:position).and_return(5)

      helper.work_package_css_classes(stub_work_package).should include("status-5")
    end

    it "should return the position of the work_package's priority" do
      priority = double('priority')

      stub_work_package.stub!(:priority).and_return(priority)
      priority.stub!(:position).and_return(5)

      helper.work_package_css_classes(stub_work_package).should include("priority-5")
    end

    it "should have a closed class if the work_package is closed" do
      stub_work_package.stub!(:closed?).and_return(true)

      helper.work_package_css_classes(stub_work_package).should include("closed")
    end

    it "should not have a closed class if the work_package is not closed" do
      stub_work_package.stub!(:closed?).and_return(false)

      helper.work_package_css_classes(stub_work_package).should_not include("closed")
    end

    it "should have an overdue class if the work_package is overdue" do
      stub_work_package.stub!(:overdue?).and_return(true)

      helper.work_package_css_classes(stub_work_package).should include("overdue")
    end

    it "should not have an overdue class if the work_package is not overdue" do
      stub_work_package.stub!(:overdue?).and_return(false)

      helper.work_package_css_classes(stub_work_package).should_not include("overdue")
    end

    it "should have a child class if the work_package is a child" do
      stub_work_package.stub!(:child?).and_return(true)

      helper.work_package_css_classes(stub_work_package).should include("child")
    end

    it "should not have a child class if the work_package is not a child" do
      stub_work_package.stub!(:child?).and_return(false)

      helper.work_package_css_classes(stub_work_package).should_not include("child")
    end

    it "should have a parent class if the work_package is a parent" do
      stub_work_package.stub!(:leaf?).and_return(false)

      helper.work_package_css_classes(stub_work_package).should include("parent")
    end

    it "should not have a parent class if the work_package is not a parent" do
      stub_work_package.stub!(:leaf?).and_return(true)

      helper.work_package_css_classes(stub_work_package).should_not include("parent")
    end

    it "should have a created-by-me class if the work_package is a created by the current user" do
      stub_user = double('user', :logged? => true, :id => 5)
      User.stub!(:current).and_return(stub_user)
      stub_work_package.stub!(:author_id).and_return(5)

      helper.work_package_css_classes(stub_work_package).should include("created-by-me")
    end

    it "should not have a created-by-me class if the work_package is not created by the current user" do
      stub_user = double('user', :logged? => true, :id => 5)
      User.stub!(:current).and_return(stub_user)
      stub_work_package.stub!(:author_id).and_return(4)

      helper.work_package_css_classes(stub_work_package).should_not include("created-by-me")
    end

    it "should not have a created-by-me class if the work_package is the current user is not logged in" do
      helper.work_package_css_classes(stub_work_package).should_not include("created-by-me")
    end

    it "should have a assigned-to-me class if the work_package is a created by the current user" do
      stub_user = double('user', :logged? => true, :id => 5)
      User.stub!(:current).and_return(stub_user)
      stub_work_package.stub!(:assigned_to_id).and_return(5)

      helper.work_package_css_classes(stub_work_package).should include("assigned-to-me")
    end

    it "should not have a assigned-to-me class if the work_package is not created by the current user" do
      stub_user = double('user', :logged? => true, :id => 5)
      User.stub!(:current).and_return(stub_user)
      stub_work_package.stub!(:assigned_to_id).and_return(4)

      helper.work_package_css_classes(stub_work_package).should_not include("assigned-to-me")
    end

    it "should not have a assigned-to-me class if the work_package is the current user is not logged in" do
      helper.work_package_css_classes(stub_work_package).should_not include("assigned-to-me")
    end
  end

  describe :work_package_form_estimated_hours_attribute do
    it "should output the estimated hours value with a precision of 2" do
      stub_work_package.estimated_hours = 3

      attribute = inside_form do |f|
        helper.work_package_form_estimated_hours_attribute(f, stub_work_package, {})
      end

      attribute.field.should have_selector('input#work_package_estimated_hours[@value="3.00"]')
    end
  end

  describe :work_package_form_custom_values_attribute do
    let(:stub_custom_value) { FactoryGirl.build_stubbed(:work_package_custom_value) }
    let(:expected) { "field contents" }

    before do
      stub_work_package.stub!(:custom_field_values).and_return([stub_custom_value])

      helper.should_receive(:custom_field_tag_with_label).with(:work_package, stub_custom_value).and_return(expected)
    end

    it "should return an array for an element for every value" do
      helper.work_package_form_custom_values_attribute(form, stub_work_package, {}).size.should == 1
    end

    it "should return the result inside the field" do
      helper.work_package_form_custom_values_attribute(form, stub_work_package, {}).first.field.should == expected
    end
  end

  describe :work_package_form_status_attribute do
    let(:status1) { FactoryGirl.build_stubbed(:issue_status) }
    let(:status2) { FactoryGirl.build_stubbed(:issue_status) }

    it "should return a select with every available status as an option" do
      stub_work_package.stub!(:new_statuses_allowed_to)
                       .with(stub_user, true)
                       .and_return([status1, status2])

      stub_work_package.status = status1

      attribute = inside_form do |f|
        helper.work_package_form_status_attribute(f, stub_work_package, :user => stub_user)
      end

      status1_selector = "select#work_package_status_id option[@value='#{status1.id}'][@selected='selected']"
      status2_selector = "select#work_package_status_id option[@value='#{status1.id}']"

      attribute.field.should have_selector(status1_selector)
      attribute.field.should have_selector(status2_selector)
    end

    it "should return a label and the name of the current status if no new status is available" do
      stub_work_package.stub!(:new_statuses_allowed_to)
                       .with(stub_user, true)
                       .and_return([])

      stub_work_package.status = status1

      attribute = inside_form do |f|
        helper.work_package_form_status_attribute(f, stub_work_package, :user => stub_user)
      end

      attribute.field.should have_text(WorkPackage.human_attribute_name(:status))
      attribute.field.should have_text(status1.name)
    end
  end
end
