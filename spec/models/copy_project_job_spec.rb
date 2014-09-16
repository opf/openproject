#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe CopyProjectJob do
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role, permissions: [:copy_projects]) }
  let(:params) { { name: 'Copy', identifier: 'copy' } }

  shared_context 'copy project' do
    before do
      copy_project_job = CopyProjectJob.new(user,
                                            project_to_copy,
                                            params,
                                            [],
                                            [:members],
                                            false)

      copy_project_job.perform
    end
  end

  before { User.stub(:current).and_return(user) }
  after { User.current = nil }

  describe 'perform' do
    describe 'subproject' do
      let(:params) { { name: 'Copy', identifier: 'copy', parent_id: project.id } }
      let(:subproject) { FactoryGirl.create(:project, parent: project) }

      describe 'invalid parent' do
        before { UserMailer.should_receive(:copy_project_failed).and_return(double("mailer", deliver: true)) }

        include_context 'copy project' do
          let(:project_to_copy) { subproject }
        end

        it { expect(Project.all).to match_array([project, subproject]) }
      end

      describe 'valid parent' do
        let(:role_add_subproject) { FactoryGirl.create(:role, permissions: [:add_subprojects]) }
        let(:member_add_subproject) { FactoryGirl.create(:member,
                                                         user: user,
                                                         project: project,
                                                         roles: [role_add_subproject]) }

        before do
          UserMailer.should_receive(:copy_project_succeeded).and_return(double("mailer", deliver: true))

          member_add_subproject
        end

        include_context 'copy project' do
          let(:project_to_copy) { subproject }
        end

        subject { Project.find_by_identifier('copy') }

        it { expect(subject).not_to be_nil }

        it { expect(subject.parent).to eql(project) }
      end

      describe "valid user" do
        let(:subproject_to_be_copied) {
          FactoryGirl.create(:project, parent: project)
        }
        include_context "copy project" do
          let(:project_to_copy) { subproject_to_be_copied }
        end

        it { expect(User.current).to eql(user) }
      end
    end
  end
end
