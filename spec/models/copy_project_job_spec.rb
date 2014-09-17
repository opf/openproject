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

describe CopyProjectJob, :type => :model do
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role, permissions: [:copy_projects]) }
  let(:params) { { name: 'Copy', identifier: 'copy' } }

  describe 'copy localizes error message' do

    let(:user_de) { FactoryGirl.create(:admin, language: :de) }
    let(:source_project) { FactoryGirl.create(:project) }
    let(:target_project) { FactoryGirl.create(:project) }

    let(:copy_job) { CopyProjectJob.new user_de,
                                        source_project,
                                        target_project,
                                        [], # enabled modules
                                        [], # associations
                                        false } # send mails

    before do
      # 'Delayed Job' uses a work around to get Rails 3 mailers working with it
      # (see https://github.com/collectiveidea/delayed_job#rails-3-mailers).
      # Thus, we need to return a message object here, otherwise 'Delayed Job'
      # will complain about an object without a method #deliver.
      allow(UserMailer).to receive(:copy_project_failed).and_return(double("Mail::Message", deliver: true))
    end

    it 'sets locale correctly' do
      expect(copy_job).to receive(:create_project_copy) do |*args|
        expect(I18n.locale).to eq(:de)
        [nil, nil]
      end

      copy_job.perform
    end
  end


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

  describe 'perform' do
    before do
      allow(User).to receive(:current).and_return(user)
      expect(User).to receive(:current=).with(user)
    end

    describe 'subproject' do
      let(:params) { { name: 'Copy', identifier: 'copy', parent_id: project.id } }
      let(:subproject) { FactoryGirl.create(:project, parent: project) }

      describe 'invalid parent' do
        before { expect(UserMailer).to receive(:copy_project_failed).and_return(double("mailer", deliver: true)) }

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
          expect(UserMailer).to receive(:copy_project_succeeded).and_return(double("mailer", deliver: true))

          member_add_subproject
        end

        include_context 'copy project' do
          let(:project_to_copy) { subproject }
        end

        subject { Project.find_by_identifier('copy') }

        it { expect(subject).not_to be_nil }

        it { expect(subject.parent).to eql(project) }
      end
    end
  end
end
