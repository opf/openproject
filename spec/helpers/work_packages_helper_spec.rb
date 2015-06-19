#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackagesHelper, type: :helper do
  let(:stub_work_package) { FactoryGirl.build_stubbed(:work_package) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project) }
  let(:stub_type) { FactoryGirl.build_stubbed(:type) }
  let(:label_placeholder) { '<label>blubs</label>'.html_safe }
  let(:form) do
    double('form',
           select: '',
           label: label_placeholder).as_null_object
  end
  let(:stub_user) { FactoryGirl.build_stubbed(:user) }

  def inside_form(&_block)
    ret = ''

    form_for(stub_work_package, as: 'work_package', url: work_package_path(stub_work_package)) do |f|
      ret = yield f
    end

    ret
  end

  describe '#work_package_breadcrumb' do
    it 'should provide a link to index as the first element and all ancestors as links' do
      index_link = double('work_package_index_link')
      ancestors_links = double('ancestors_links')

      allow(helper).to receive(:ancestors_links).and_return([ancestors_links])
      allow(helper).to receive(:work_package_index_link).and_return(index_link)

      @expectation = [index_link, ancestors_links]

      expect(helper).to receive(:breadcrumb_paths).with(*@expectation)

      helper.work_package_breadcrumb
    end
  end

  describe '#ancestors_links' do
    it 'should return a list of links for every ancestor' do
      ancestors = [double('ancestor1', id: 1),
                   double('ancestor2', id: 2)]

      allow(controller).to receive(:ancestors).and_return(ancestors)

      ancestors.each_with_index do |ancestor, index|
        expect(helper.ancestors_links[index]).to have_selector("a[href='#{work_package_path(ancestor.id)}']", text: "##{ancestor.id}")

      end
    end
  end

  describe '#link_to_work_package' do
    let(:open_status) { FactoryGirl.build_stubbed(:status, is_closed: false) }
    let(:closed_status) { FactoryGirl.build_stubbed(:status, is_closed: true) }

    before do
      stub_work_package.status = open_status
    end

    describe 'without parameters' do
      it 'should return a link to the work package with the id as the text' do
        link_text = Regexp.new("^##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end

      it 'should return a link to the work package with type and id as the text if type is set' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^#{stub_type.name} ##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end

      it 'should additionally return the subject' do
        text = Regexp.new("#{stub_work_package.subject}$")
        expect(helper.link_to_work_package(stub_work_package)).to have_text(text)
      end

      it 'should prepend an invisible closed information if the work package is closed' do
        stub_work_package.status = closed_status

        expect(helper.link_to_work_package(stub_work_package)).to have_selector('a span.hidden-for-sighted', text: 'closed')
      end
    end

    describe 'with the all_link option provided' do
      it 'should return a link to the work package with the type, id, and subject as the text' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^#{stub_type} ##{stub_work_package.id}: #{stub_work_package.subject}$")
        expect(helper.link_to_work_package(stub_work_package, all_link: true)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end
    end

    describe 'when truncating' do
      it 'should truncate the subject if the subject is longer than the specified amount' do
        stub_work_package.subject = '12345678'

        text = Regexp.new('1234...$')
        expect(helper.link_to_work_package(stub_work_package, truncate: 7)).to have_text(text)
      end

      it 'should not truncate the subject if the subject is shorter than the specified amount' do
        stub_work_package.subject = '1234567'

        text = Regexp.new('1234567$')
        expect(helper.link_to_work_package(stub_work_package, truncate: 7)).to have_text(text)
      end
    end

    describe 'when omitting the subject' do
      it 'should omit the subject' do
        expect(helper.link_to_work_package(stub_work_package, subject: false)).not_to have_text(stub_work_package.subject)
      end
    end

    describe 'when omitting the type' do
      it 'should omit the type' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package, type: false)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end
    end

    describe 'with a project' do
      let(:text) { Regexp.new("^#{stub_project.name} -") }

      before do
        stub_work_package.project = stub_project
      end

      it 'should prepend the project if parameter set to true' do
        expect(helper.link_to_work_package(stub_work_package, project: true)).to have_text(text)
      end

      it 'should not have the project name if the parameter is missing/false' do
        expect(helper.link_to_work_package(stub_work_package)).not_to have_text(text)
      end
    end

    describe 'when only wanting the id' do
      it 'should return a link with the id as text only even if the work package has a type' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^##{stub_work_package.id}$")
        expect(helper.link_to_work_package(stub_work_package, id_only: true)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end

      it 'should not have the subject as text' do
        expect(helper.link_to_work_package(stub_work_package, id_only: true)).not_to have_text(stub_work_package.subject)
      end
    end

    describe 'when only wanting the subject' do
      it 'should return a link with the subject as text' do
        link_text = Regexp.new("^#{stub_work_package.subject}$")
        expect(helper.link_to_work_package(stub_work_package, subject_only: true)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end
    end

    describe 'with the status displayed' do
      it 'should return a link with the status name contained in the text' do
        stub_work_package.type = stub_type

        link_text = Regexp.new("^#{stub_type.name} ##{stub_work_package.id} #{stub_work_package.status}$")
        expect(helper.link_to_work_package(stub_work_package, status: true)).to have_selector("a[href='#{work_package_path(stub_work_package)}']", text: link_text)
      end
    end
  end

  describe '#work_package_index_link' do
    it 'should return a link to issue_index (work_packages index later)' do
      expect(helper.work_package_index_link).to have_selector("a[href='#{work_packages_path}']", text: I18n.t(:label_work_package_plural))
    end
  end

  describe '#work_package_show_spent_time_attribute' do
    it 'should show a spent time link pointing to the time entries of the work package' do
      allow(stub_work_package).to receive(:spent_hours).and_return(5.0)

      field = helper.work_package_show_spent_time_attribute(stub_work_package).field

      expected_href = work_package_time_entries_path(stub_work_package)

      expect(field).to have_css(".-spent-time a[@href='#{ expected_href }']", text: '5.0')
    end

    it "should show a '-' if spent time is 0" do
      allow(stub_work_package).to receive(:spent_hours).and_return(0.0)

      field = helper.work_package_show_spent_time_attribute(stub_work_package).field

      expect(field).to have_css('.-spent-time', text: '-')
    end
  end

  # Testing private method here.
  # Only doing so because this method is an exception.
  # All other show... methods are public.
  # TODO: check wether the method can be made public.
  describe '#work_package_show_custom_fields' do
    let(:stub_custom_field) do
      stub_custom_field = FactoryGirl.build_stubbed(:custom_field,
                                                    name: 'My Custom Field')
    end

    let(:stub_custom_value) do
      FactoryGirl.build_stubbed(:work_package_custom_value, customized: stub_work_package,
                                                            custom_field: stub_custom_field,
                                                            value: '5')
    end

    it 'should show the field name unchanged' do
      allow(stub_work_package).to receive(:custom_field_values).and_return([stub_custom_value])

      attributes = helper.send(:work_package_show_custom_fields, stub_work_package)

      expect(attributes.length).to eql(1)

      expected_css_class = ".attributes-key-value--key.-custom_field.-cf_#{stub_custom_field.id}"
      expect(attributes[0].field).to have_css(expected_css_class, text: stub_custom_field.name)
    end
  end

  describe '#work_package_form_category_attribute' do
    let(:stub_project) { FactoryGirl.build_stubbed(:project) }
    let(:stub_category) { FactoryGirl.build_stubbed(:category) }

    before do
      # set sensible defaults
      allow(helper).to receive(:authorize_for).and_return(false)
      allow(stub_project).to receive(:categories).and_return([stub_category])
    end

    it 'should return nothing if the project has no categories assigned' do
      allow(stub_project).to receive(:categories).and_return([])

      expect(helper.work_package_form_category_attribute(form, stub_work_package, project: stub_project)).to be_nil
    end

    it 'should have a :category symbol as the attribute' do
      expect(helper.work_package_form_category_attribute(form, stub_work_package, project: stub_project).attribute).to eq(:category)
    end

    it "should render a select with the project's work package categories" do
      select = 'category html'

      expect(form).to receive(:select).with(:category_id,
                                            [[stub_category.name, stub_category.id]],
                                            include_blank: true,
                                            no_label: true).and_return(select)

      expect(helper.work_package_form_category_attribute(form,
                                                         stub_work_package,
                                                         project: stub_project).field)
        .to be_html_eql("<div class=\"form--field -wide-label -break-words \">#{label_placeholder}
                         <span class=\"form--field-container\">category html</span>
                         </div>")
    end

    it 'should add an additional remote link to create new categories if allowed' do
      remote = 'remote'

      allow(helper).to receive(:authorize_for).and_return(true)

      expect(helper).to receive(:prompt_to_remote)
        .with(*([anything] * 3), project_categories_path(stub_project), anything)
        .and_return(remote)

      expect(helper.work_package_form_category_attribute(form, stub_work_package, project: stub_project).field).to include(remote)
    end
  end

  describe '#work_package_css_classes' do
    let(:statuses) { (1..5).map { |_i| FactoryGirl.build_stubbed(:status) } }
    let(:priority) { FactoryGirl.build_stubbed :priority, is_default: true }
    let(:status) { statuses[0] }
    let(:stub_work_package) {
      FactoryGirl.build_stubbed(:work_package,
                                status: status,
                                priority: priority)
    }

    it 'should always have the work_package class' do
      expect(helper.work_package_css_classes(stub_work_package)).to include('work_package')
    end

    it "should return the position of the work_package's status" do
      status = double('status', is_closed?: false)

      allow(stub_work_package).to receive(:status).and_return(status)
      allow(status).to receive(:position).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include('status-5')
    end

    it "should return the position of the work_package's priority" do
      priority = double('priority')

      allow(stub_work_package).to receive(:priority).and_return(priority)
      allow(priority).to receive(:position).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include('priority-5')
    end

    it 'should have a closed class if the work_package is closed' do
      allow(stub_work_package).to receive(:closed?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).to include('closed')
    end

    it 'should not have a closed class if the work_package is not closed' do
      allow(stub_work_package).to receive(:closed?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('closed')
    end

    it 'should have an overdue class if the work_package is overdue' do
      allow(stub_work_package).to receive(:overdue?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).to include('overdue')
    end

    it 'should not have an overdue class if the work_package is not overdue' do
      allow(stub_work_package).to receive(:overdue?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('overdue')
    end

    it 'should have a child class if the work_package is a child' do
      allow(stub_work_package).to receive(:child?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).to include('child')
    end

    it 'should not have a child class if the work_package is not a child' do
      allow(stub_work_package).to receive(:child?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('child')
    end

    it 'should have a parent class if the work_package is a parent' do
      allow(stub_work_package).to receive(:leaf?).and_return(false)

      expect(helper.work_package_css_classes(stub_work_package)).to include('parent')
    end

    it 'should not have a parent class if the work_package is not a parent' do
      allow(stub_work_package).to receive(:leaf?).and_return(true)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('parent')
    end

    it 'should have a created-by-me class if the work_package is a created by the current user' do
      stub_user = double('user', logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:author_id).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include('created-by-me')
    end

    it 'should not have a created-by-me class if the work_package is not created by the current user' do
      stub_user = double('user', logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:author_id).and_return(4)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('created-by-me')
    end

    it 'should not have a created-by-me class if the work_package is the current user is not logged in' do
      expect(helper.work_package_css_classes(stub_work_package)).not_to include('created-by-me')
    end

    it 'should have a assigned-to-me class if the work_package is a created by the current user' do
      stub_user = double('user', logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:assigned_to_id).and_return(5)

      expect(helper.work_package_css_classes(stub_work_package)).to include('assigned-to-me')
    end

    it 'should not have a assigned-to-me class if the work_package is not created by the current user' do
      stub_user = double('user', logged?: true, id: 5)
      allow(User).to receive(:current).and_return(stub_user)
      allow(stub_work_package).to receive(:assigned_to_id).and_return(4)

      expect(helper.work_package_css_classes(stub_work_package)).not_to include('assigned-to-me')
    end

    it 'should not have a assigned-to-me class if the work_package is the current user is not logged in' do
      expect(helper.work_package_css_classes(stub_work_package)).not_to include('assigned-to-me')
    end
  end

  describe '#work_package_form_estimated_hours_attribute' do
    it 'should output the estimated hours value with a precision of 2' do
      stub_work_package.estimated_hours = 3

      attribute = inside_form do |f|
        helper.work_package_form_estimated_hours_attribute(f, stub_work_package, {})
      end

      expect(attribute.field).to have_selector('input#work_package_estimated_hours[@value="3.00"]')
    end
  end

  describe '#work_package_form_custom_values_attribute' do
    let(:stub_custom_value) { FactoryGirl.build_stubbed(:work_package_custom_value) }
    let(:field_content) { 'field contents' }
    let(:expected) { "<div class=\"form--field -wide-label -break-words \">#{field_content}</div>" }

    before do
      allow(stub_work_package).to receive(:custom_field_values).and_return([stub_custom_value])
      cf_form = double('custom_value_form_double').as_null_object
      allow(form).to receive(:fields_for_custom_fields).and_yield(cf_form)

      expect(cf_form).to receive(:custom_field).and_return(field_content)
    end

    it 'should return an array for an element for every value' do
      expect(helper.work_package_form_custom_values_attribute(form, stub_work_package, {}).size).to eq(1)
    end

    it 'should return the result inside the field' do
      expect(helper.work_package_form_custom_values_attribute(form, stub_work_package, {}).first.field).to eq(expected)
    end
  end

  describe '#work_package_form_status_attribute' do
    let(:status1) { FactoryGirl.build_stubbed(:status) }
    let(:status2) { FactoryGirl.build_stubbed(:status) }

    it 'should return a select with every available status as an option' do
      allow(stub_work_package).to receive(:new_statuses_allowed_to)
        .with(stub_user)
        .and_return([status1, status2])

      stub_work_package.status = status1

      attribute = inside_form do |f|
        helper.work_package_form_status_attribute(f, stub_work_package, user: stub_user)
      end

      status1_selector = "select#work_package_status_id option[@value='#{status1.id}'][@selected='selected']"
      status2_selector = "select#work_package_status_id option[@value='#{status1.id}']"

      expect(attribute.field).to have_selector(status1_selector)
      expect(attribute.field).to have_selector(status2_selector)
    end

    it 'should return a label and the name of the current status if no new status is available' do
      allow(stub_work_package).to receive(:new_statuses_allowed_to)
        .with(stub_user)
        .and_return([])

      stub_work_package.status = status1

      attribute = inside_form do |f|
        helper.work_package_form_status_attribute(f, stub_work_package, user: stub_user)
      end

      expect(attribute.field).to have_text(WorkPackage.human_attribute_name(:status))
      expect(attribute.field).to have_text(status1.name)
    end
  end
end
