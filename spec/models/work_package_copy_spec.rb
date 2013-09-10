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

describe WorkPackage do
  describe :copy do
    let(:user) { FactoryGirl.create(:user) }
    let (:custom_field) { FactoryGirl.create(:work_package_custom_field) }
    let(:source_type) { FactoryGirl.create(:type,
                                           custom_fields: [custom_field]) }
    let(:source_project) { FactoryGirl.create(:project,
                                              types: [source_type]) }
    let(:work_package) { FactoryGirl.create(:work_package,
                                            project: source_project,
                                            type: source_type,
                                            author: user) }
    let(:custom_value) { FactoryGirl.create(:work_package_custom_value,
                                            custom_field: custom_field,
                                            customized: work_package,
                                            value: false) }

    shared_examples_for "copied work package" do
      subject { copy.id }

      it { should_not eq(work_package.id) }
    end

    describe "to the same project" do
      let(:copy) { work_package.move_to_project(source_project, nil, :copy => true) }

      it_behaves_like "copied work package"

      context :project do
        subject { copy.project }

        it { should eq(source_project) }
      end
    end

    describe "to a different project" do
      let(:target_type) { FactoryGirl.create(:type) }
      let(:target_project) { FactoryGirl.create(:project,
                                                types: [target_type]) }
      let(:copy) { work_package.move_to_project(target_project, target_type, copy: true) }

      it_behaves_like "copied work package"

      context :project do
        subject { copy.project_id }

        it { should eq(target_project.id) }
      end

      context :type do
        subject { copy.type_id }

        it { should eq(target_type.id) }
      end

      context :custom_fields do
        before { custom_value }

        subject { copy.custom_value_for(custom_field.id) }

        it { should be_nil }
      end

      describe :attributes do
        let(:copy) { work_package.move_to_project(target_project,
                                                  target_type,
                                                  copy: true,
                                                  attributes: attributes) }

        context :assigned_to do
          let(:target_user) { FactoryGirl.create(:user) }
          let(:target_project_member) { FactoryGirl.create(:member,
                                                           project: target_project,
                                                           principal: target_user,
                                                           roles: [FactoryGirl.create(:role)]) }
          let(:attributes) { { assigned_to_id: target_user.id } }

          before { target_project_member }

          it_behaves_like "copied work package"

          subject { copy.assigned_to_id }

          it { should eq(target_user.id) }
        end

        context :status do
          let(:target_status) { FactoryGirl.create(:issue_status) }
          let(:attributes) { { status_id: target_status.id } }

          it_behaves_like "copied work package"

          subject { copy.status_id }

          it { should eq(target_status.id) }
        end

        context :date do
          let(:target_date) { Date.today + 14 }

          context :start do
            let(:attributes) { { start_date: target_date } }

            it_behaves_like "copied work package"

            subject { copy.start_date }

            it { should eq(target_date) }
          end

          context :end do
            let(:attributes) { { due_date: target_date } }

            it_behaves_like "copied work package"

            subject { copy.due_date }

            it { should eq(target_date) }
          end
        end
      end

      describe "private project" do
        let(:role) { FactoryGirl.create(:role,
                                        permissions: [:view_work_packages]) }
        let(:target_project) { FactoryGirl.create(:project,
                                                  is_public: false,
                                                  types: [target_type]) }
        let(:source_project_member) { FactoryGirl.create(:member,
                                                         project: source_project,
                                                         principal: user,
                                                         roles: [role]) }

        before do
          source_project_member
          User.stub(:current).and_return user
        end

        it_behaves_like "copied work package"

        context "pre-condition" do
          subject { work_package.recipients }

          it { should include(work_package.author.mail) }
        end

        subject { copy.recipients }

        it { should_not include(copy.author.mail) }
      end
    end
  end
end
