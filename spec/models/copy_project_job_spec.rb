#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe CopyProjectJob, type: :model do
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role, permissions: [:copy_projects]) }
  let(:params) { { name: 'Copy', identifier: 'copy' } }
  let(:maildouble) { double('Mail::Message', deliver: true) }

  before do
    allow(maildouble).to receive(:deliver_now).and_return nil
  end

  describe 'copy localizes error message' do
    let(:user_de) { FactoryGirl.create(:admin, language: :de) }
    let(:source_project) { FactoryGirl.create(:project) }
    let(:target_project) { FactoryGirl.create(:project) }

    let(:copy_job) {
      CopyProjectJob.new user_id: user_de.id,
                         source_project_id: source_project.id,
                         target_project_params: target_project,
                         associations_to_copy: []
    }

    before do
      # 'Delayed Job' uses a work around to get Rails 3 mailers working with it
      # (see https://github.com/collectiveidea/delayed_job#rails-3-mailers).
      # Thus, we need to return a message object here, otherwise 'Delayed Job'
      # will complain about an object without a method #deliver.
      allow(UserMailer).to receive(:copy_project_failed).and_return(maildouble)
    end

    it 'sets locale correctly' do
      expect(copy_job).to receive(:create_project_copy) do |*_args|
        expect(I18n.locale).to eq(:de)
        [nil, nil]
      end

      copy_job.perform
    end
  end

  describe 'copy project succeeds with errors' do
    let(:admin) { FactoryGirl.create(:admin) }
    let(:source_project) { FactoryGirl.create(:project, types: [type]) }
    let!(:work_package) { FactoryGirl.create(:work_package, project: source_project, type: type) }
    let(:type) { FactoryGirl.create(:type_bug) }
    let (:custom_field) {
      FactoryGirl.create(:work_package_custom_field,
                         name: 'required_field',
                         field_format: 'text',
                         is_required: true,
                         is_for_all: true)
    }
    let(:copy_job) {
      CopyProjectJob.new user_id: admin.id,
                         source_project_id: source_project.id,
                         target_project_params: params,
                         associations_to_copy: [:work_packages]
    } # send mails
    let(:params) { { name: 'Copy', identifier: 'copy', type_ids: [type.id], work_package_custom_field_ids: [custom_field.id] } }
    let(:expected_error_message) { "#{WorkPackage.model_name.human} '#{work_package.type.name} #: #{work_package.subject}': #{custom_field.name} #{I18n.t('errors.messages.blank')}." }

    before do
      source_project.work_package_custom_fields << custom_field
      type.custom_fields << custom_field

      allow(User).to receive(:current).and_return(admin)

      # 'Delayed Job' uses a work around to get Rails 3 mailers working with it
      # (see https://github.com/collectiveidea/delayed_job#rails-3-mailers).
      # Thus, we need to return a message object here, otherwise 'Delayed Job'
      # will complain about an object without a method #deliver.
      allow(UserMailer).to receive(:copy_project_succeeded).and_return(maildouble)

      @copied_project, @errors = copy_job.send(:create_project_copy,
                                               source_project,
                                               params,
                                               [:work_packages], # associations
                                               false)
    end

    it 'copies the project' do
      expect(Project.find_by(identifier: params[:identifier])).to eq(@copied_project)
    end

    it 'sets descriptive validation errors' do
      expect(@errors.first).to eq(expected_error_message)
    end
  end

  shared_context 'copy project' do
    before do
      copy_project_job = CopyProjectJob.new(user_id: user.id,
                                            source_project_id: project_to_copy.id,
                                            target_project_params: params,
                                            associations_to_copy: [:members])
      copy_project_job.perform
    end
  end

  describe 'perform' do
    before do
      login_as(user)
      expect(User).to receive(:current=).with(user)
    end

    describe 'subproject' do
      let(:params) { { name: 'Copy', identifier: 'copy', parent_id: project.id } }
      let(:subproject) { FactoryGirl.create(:project, parent: project) }

      describe 'invalid parent' do
        before do expect(UserMailer).to receive(:copy_project_failed).and_return(maildouble) end

        include_context 'copy project' do
          let(:project_to_copy) { subproject }
        end

        it { expect(Project.all).to match_array([project, subproject]) }
      end

      describe 'valid parent' do
        let(:role_add_subproject) { FactoryGirl.create(:role, permissions: [:add_subprojects]) }
        let(:member_add_subproject) {
          FactoryGirl.create(:member,
                             user: user,
                             project: project,
                             roles: [role_add_subproject])
        }

        before do
          expect(UserMailer).to receive(:copy_project_succeeded).and_return(maildouble)

          member_add_subproject
        end

        include_context 'copy project' do
          let(:project_to_copy) { subproject }
        end

        subject { Project.find_by(identifier: 'copy') }

        it 'copies the project' do
          expect(subject).not_to be_nil
          expect(subject.parent).to eql(project)

          expect(subproject.reload.enabled_module_names).not_to be_empty
        end
      end
    end
  end
end
