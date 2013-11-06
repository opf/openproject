#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::PlanningElementsController do
  # ===========================================================
  # Helpers
  def self.become_admin
    let(:current_user) { FactoryGirl.create(:admin) }
  end

  def self.become_non_member(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        current_user.memberships.select {|m| m.project_id == p.id}.each(&:destroy)
      end
    end
  end

  def self.become_member_with_view_planning_element_permissions(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, :permissions => [:view_work_packages])

      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        member = FactoryGirl.build(:member, :user => current_user, :project => p)
        member.roles = [role]
        member.save!
      end
    end
  end

  def self.become_member_with_edit_planning_element_permissions(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, :permissions => [:edit_work_packages])

      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        member = FactoryGirl.build(:member, :user => current_user, :project => p)
        member.roles = [role]
        member.save!
      end
    end
  end

  def self.become_member_with_delete_planning_element_permissions(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, :permissions => [:delete_work_packages])

      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        member = FactoryGirl.build(:member, :user => current_user, :project => project)
        member.roles = [role]
        member.save!
      end
    end
  end

  before do
    User.stub(:current).and_return current_user

    FactoryGirl.create :priority, is_default: true
    FactoryGirl.create :default_status
  end

  # ===========================================================
  # API tests

  describe 'index.xml' do
    become_admin

    describe 'w/ list of ids' do
      describe 'w/ an unknown work package id' do
        it 'renders an empty list' do
          get 'index', :ids => '4711', :format => 'xml'

          assigns(:planning_elements).should == []
        end
      end

      describe 'w/ known work package ids in one project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }
        let(:work_package) { FactoryGirl.create(:work_package, :project_id => project.id) }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders an empty list' do
            get 'index', :ids => work_package.id.to_s, :format => 'xml'

            assigns(:planning_elements).should == []
          end
        end

        describe 'w/ the current user being a member with view_work_packages permissions' do
          become_member_with_view_planning_element_permissions

          before do
            get 'index', :ids => "", :format => 'xml'
          end

          describe 'w/o any planning elements within the project' do
            it 'assigns an empty planning_elements array' do
              assigns(:planning_elements).should == []
            end

            it 'renders the index builder template' do
              response.should render_template('planning_elements/index', :formats => ["api"])
            end
          end

          describe 'w/ 3 planning elements within the project' do
            before do
              @created_planning_elements = [
                FactoryGirl.create(:work_package, :project_id => project.id),
                FactoryGirl.create(:work_package, :project_id => project.id),
                FactoryGirl.create(:work_package, :project_id => project.id)
              ]
              get 'index', :ids => @created_planning_elements.map(&:id).join(","), :format => 'xml'
            end

            it 'assigns a planning_elements array containing all three elements' do
              assigns(:planning_elements).should =~ @created_planning_elements
            end

            it 'renders the index builder template' do
              response.should render_template('planning_elements/index', :formats => ["api"])
            end
          end
        end
      end

      describe 'w/ known work package ids in multiple projects' do
        let(:project_a) { FactoryGirl.create(:project, :identifier => 'project_a') }
        let(:project_b) { FactoryGirl.create(:project, :identifier => 'project_b') }
        let(:project_c) { FactoryGirl.create(:project, :identifier => 'project_c') }
        before do
          @project_a_wps = [
            FactoryGirl.create(:work_package, :project_id => project_a.id),
            FactoryGirl.create(:work_package, :project_id => project_a.id),
          ]
          @project_b_wps = [
            FactoryGirl.create(:work_package, :project_id => project_b.id),
            FactoryGirl.create(:work_package, :project_id => project_b.id),
          ]
          @project_c_wps = [
            FactoryGirl.create(:work_package, :project_id => project_c.id),
            FactoryGirl.create(:work_package, :project_id => project_c.id)
          ]
        end

        describe 'w/ an unknown pe in the list' do
          become_admin { [project_a, project_b] }

          it 'renders only existing work packages' do
            get 'index', :ids => [@project_a_wps[0].id, @project_b_wps[0].id, '4171', '5555'].join(","), :format => 'xml'

            assigns(:planning_elements).should =~ [@project_a_wps[0], @project_b_wps[0]]
          end
        end

        describe 'w/ an inaccessible pe in the list' do
          become_member_with_view_planning_element_permissions { [project_a, project_b] }
          become_non_member { [project_c] }

          it 'renders only accessable work packages' do
            get 'index', :ids => [@project_a_wps[0].id, @project_b_wps[0].id, @project_c_wps[0].id, @project_c_wps[1].id].join(","), :format => 'xml'

            assigns(:planning_elements).should =~ [@project_a_wps[0], @project_b_wps[0]]
          end

          it 'renders only accessable work packages' do
            get 'index', :ids => [@project_c_wps[0].id, @project_c_wps[1].id].join(","), :format => 'xml'

            assigns(:planning_elements).should =~ []
          end
        end

        describe 'w/ multiple work packages in multiple projects' do
          become_member_with_view_planning_element_permissions { [project_a, project_b, project_c] }

          it 'renders all work packages' do
            get 'index', :ids => (@project_a_wps + @project_b_wps + @project_c_wps).map(&:id).join(","), :format => 'xml'

            assigns(:planning_elements).should =~ (@project_a_wps + @project_b_wps + @project_c_wps)
          end
        end
      end
    end

    describe 'w/ list of projects' do
      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'index', :project_id => 'project_x,project_b', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'index', :project_id => project.identifier, :format => 'xml'

            response.response_code.should == 403
          end
        end

        describe 'w/ the current user being a member with view_work_packages permissions' do
          become_member_with_view_planning_element_permissions

          before do
            get 'index', :project_id => project.id, :format => 'xml'
          end

          describe 'w/o any planning elements within the project' do
            it 'assigns an empty planning_elements array' do
              assigns(:planning_elements).should == []
            end

            it 'renders the index builder template' do
              response.should render_template('planning_elements/index', :formats => ["api"])
            end
          end

          describe 'w/ 3 planning elements within the project' do
            before do
              @created_planning_elements = [
                FactoryGirl.create(:work_package, :project_id => project.id),
                FactoryGirl.create(:work_package, :project_id => project.id),
                FactoryGirl.create(:work_package, :project_id => project.id)
              ].map do |model|
                OpenStruct.new(model.attributes).tap { |s| s.child_ids = [] }
              end
              get 'index', :project_id => project.id, :format => 'xml'
            end

            it 'assigns a planning_elements array containing all three elements' do
              assigns(:planning_elements).should =~ @created_planning_elements
            end

            it 'renders the index builder template' do
              response.should render_template('planning_elements/index', :formats => ["api"])
            end
          end
        end
      end

      describe 'w/ multiple known projects' do
        let(:project_a) { FactoryGirl.create(:project, :identifier => 'project_a') }
        let(:project_b) { FactoryGirl.create(:project, :identifier => 'project_b') }
        let(:project_c) { FactoryGirl.create(:project, :identifier => 'project_c') }

        describe 'w/ an unknown project in the list' do
          become_admin { [project_a, project_b] }

          it 'renders a 404 Not Found page' do
            get 'index', :project_id => 'project_x,project_b', :format => 'xml'

            response.response_code.should == 404
          end
        end

        describe 'w/ a project in the list, the current user may not access' do
          before { project_a; project_b }
          become_non_member { [project_b] }
          before do
            get 'index', :project_id => 'project_a,project_b', :format => 'xml'
          end


          it 'assigns an empty planning_elements array' do
            assigns(:planning_elements).should == []
          end

          it 'renders the index builder template' do
            response.should render_template('planning_elements/index', :formats => ["api"])
          end
        end

        describe 'w/ the current user being a member with view_work_packages permission' do
          become_member_with_view_planning_element_permissions { [project_a, project_b] }

          before do
            get 'index', :project_id => 'project_a,project_b', :format => 'xml'
          end

          describe 'w/o any planning elements within the project' do
            it 'assigns an empty planning_elements array' do
              assigns(:planning_elements).should == []
            end

            it 'renders the index builder template' do
              response.should render_template('planning_elements/index', :formats => ["api"])
            end
          end

          describe 'w/ 1 planning element in project_a and 2 in project_b' do
            before do
              @created_planning_elements = [
                FactoryGirl.create(:work_package, :project_id => project_a.id),
                FactoryGirl.create(:work_package, :project_id => project_b.id),
                FactoryGirl.create(:work_package, :project_id => project_b.id)
              ].map do |model|
                OpenStruct.new(model.attributes).tap { |s| s.child_ids = [] }
              end
              # adding another planning element, just to make sure, that the
              # result set is properly filtered
              FactoryGirl.create(:work_package, :project_id => project_c.id)
              get 'index', :project_id => 'project_a,project_b', :format => 'xml'
            end

            it 'assigns a planning_elements array containing all three elements' do
              assigns(:planning_elements).should =~ @created_planning_elements
            end

            it 'renders the index builder template' do
              response.should render_template('planning_elements/index', :formats => ["api"])
            end
          end
        end
      end
    end
  end

  describe 'create.xml' do
    let(:project) { FactoryGirl.create(:project_with_types, :is_public => false) }
    let(:author)  { FactoryGirl.create(:user) }

    become_admin

    describe 'permissions' do
      let(:planning_element) do
        FactoryGirl.build(:work_package, :author => author, :project_id => project.id)
      end

      def fetch
        post 'create', :project_id => project.identifier,
                       :format => 'xml',
                       :planning_element => planning_element.attributes
      end

      def expect_redirect_to
        Regexp.new(project_planning_elements_path(project))
      end
      let(:permission) { :edit_work_packages }

      it_should_behave_like "a controller action which needs project permissions"
    end

    describe 'with custom fields' do
      let(:type) { Type.find_by_name("None") || FactoryGirl.create(:type_standard) }

      let(:custom_field) do
        FactoryGirl.create :issue_custom_field,
          :name => "Verse",
          :field_format => "text",
          :projects => [project],
          :types => [type]
      end

      let(:planning_element) do
        FactoryGirl.build(
          :work_package,
          :author => author,
          :type => type,
          :project => project)
      end

      it 'creates a new planning element with the given custom field value' do
        post 'create',
          :project_id => project.identifier,
          :format => 'xml',
          :planning_element => planning_element.attributes.merge(:custom_fields => [
            { :id => custom_field.id, :value => "Wurst" }])
        response.response_code.should == 303

        id = response.headers["Location"].scan(/\d+/).last.to_i

        wp = WorkPackage.find_by_id id
        wp.should_not be_nil

        custom_value = wp.custom_values.find do |value|
          value.custom_field.name == custom_field.name
        end

        custom_value.should_not be_nil
        custom_value.value.should == "Wurst"
      end
    end
  end

  describe 'show.xml' do
    become_admin

    describe 'w/o a valid planning element id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => '4711', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'show', :project_id => '4711', :id => '1337', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'show', :project_id => project.id, :id => '1337', :format => 'xml'

            response.response_code.should === 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_view_planning_element_permissions

          it 'raises ActiveRecord::RecordNotFound errors' do
            lambda do
              get 'show', :project_id => project.id, :id => '1337', :format => 'xml'
            end.should raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid planning element id' do
      become_admin

      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:planning_element) { FactoryGirl.create(:work_package, :project_id => project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => planning_element.id, :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'show', :project_id => project.id, :id => planning_element.id, :format => 'xml'

            response.response_code.should == 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_view_planning_element_permissions

          it 'assigns the planning_element' do
            get 'show', :project_id => project.id, :id => planning_element.id, :format => 'xml'
            assigns(:planning_element).should == planning_element
          end

          it 'renders the show builder template' do
            get 'show', :project_id => project.id, :id => planning_element.id, :format => 'xml'
            response.should render_template('planning_elements/show', :formats => ["api"])
          end
        end
      end
    end

    describe 'with custom fields' do
      render_views

      let(:project) { FactoryGirl.create(:project) }
      let(:type) { Type.find_by_name("None") || FactoryGirl.create(:type_standard) }

      let(:custom_field) do
        FactoryGirl.create :text_issue_custom_field,
          :projects => [project],
          :types => [type]
      end

      let(:planning_element) do
        FactoryGirl.create :work_package,
          :type => type,
          :project => project,
          :custom_values => [
            CustomValue.new(:custom_field => custom_field, :value => "Mett")]
      end

      it "should render the custom field values" do
        get 'show', :project_id => project.identifier, :id => planning_element.id, :format => 'json'

        response.should be_success
        response.header['Content-Type'].should include 'application/json'
        response.body.should include "Mett"
      end
    end
  end

  describe 'update.xml' do
    let(:project) { FactoryGirl.create(:project, :is_public => false) }

    become_admin

    describe 'permissions' do
      let(:planning_element) { FactoryGirl.create(:work_package,
                                                  :project_id => project.id) }

      def fetch
        post 'update', :project_id       => project.identifier,
                       :id               => planning_element.id,
                       :planning_element => { name: "blubs" },
                       :format => 'xml'
      end
      def expect_no_content
        true
      end
      let(:permission) { :edit_work_packages }
      it_should_behave_like "a controller action which needs project permissions"
    end

    describe 'with custom fields' do
      let(:type) { Type.find_by_name("None") || FactoryGirl.create(:type_standard) }

      let(:custom_field) do
        FactoryGirl.create :text_issue_custom_field,
          :projects => [project],
          :types => [type]
      end

      let(:planning_element) do
        FactoryGirl.create :work_package,
          :type => type,
          :project => project,
          :custom_values => [
            CustomValue.new(:custom_field => custom_field, :value => "Mett")]
      end

      it 'updates the custom field value' do
        put 'update',
          :project_id => project.identifier,
          :format => 'xml',
          :id => planning_element.id,
          :planning_element => {
            :custom_fields => [
              { :id => custom_field.id, :value => "Wurst" }
            ]
          }
        response.response_code.should == 204

        wp = WorkPackage.find planning_element.id
        custom_value = wp.custom_values.find do |value|
          value.custom_field.name == custom_field.name
        end

        custom_value.should_not be_nil
        custom_value.value.should_not == "Mett"
        custom_value.value.should == "Wurst"
      end
    end
  end

  describe 'destroy.xml' do
    become_admin

    describe 'w/o a valid planning element id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'destroy', :id => '4711', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'destroy', :project_id => '4711', :id => '1337', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'destroy', :project_id => project.id, :id => '1337', :format => 'xml'

            response.response_code.should == 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_delete_planning_element_permissions

          it 'raises ActiveRecord::RecordNotFound errors' do
            lambda do
              get 'destroy', :project_id => project.id, :id => '1337', :format => 'xml'
            end.should raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid planning element id' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:planning_element) { FactoryGirl.create(:work_package, :project_id => project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'destroy', :id => planning_element.id, :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'destroy', :project_id => project.id, :id => planning_element.id, :format => 'xml'

            response.response_code.should == 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_delete_planning_element_permissions

          it 'assigns the planning_element' do
            get 'destroy', :project_id => project.id, :id => planning_element.id, :format => 'xml'

            assigns(:planning_element).should == planning_element
          end

          it 'renders the destroy builder template' do
            get 'destroy', :project_id => project.id, :id => planning_element.id, :format => 'xml'

            response.should render_template('planning_elements/destroy', :formats => ["api"])
          end

          it 'deletes the record' do
            get 'destroy', :project_id => project.id, :id => planning_element.id, :format => 'xml'
            lambda do
              planning_element.reload
            end.should raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end
end
