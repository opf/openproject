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

describe ::API::V3::Repositories::RevisionRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:representer) { described_class.new(revision) }

  let(:project) { FactoryGirl.build :project }
  let(:repository) { FactoryGirl.build :repository_subversion, project: project}
  let(:revision) {
    FactoryGirl.build(:changeset,
                      id: 42,
                      revision: '1234',
                      repository: repository,
                      comments: commit_message,
                      committer: 'foo bar <foo@example.org>',
                      committed_on: DateTime.now,
                      )
  }

  let(:commit_message) { 'Some commit message' }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json('Revision'.to_json).at_path('_type') }

    describe 'revision' do
      it { is_expected.to have_json_path('id') }

      it_behaves_like 'API V3 formattable', 'message' do
        let(:format) { 'plain' }
        let(:raw) { revision.comments }
        let(:html) { '<p>' + revision.comments + '</p>' }
      end

      describe 'identifier' do
        it { is_expected.to have_json_path('identifier') }
        it { is_expected.to be_json_eql('1234'.to_json).at_path('identifier') }
      end

      describe 'createdAt' do
        it_behaves_like 'has UTC ISO 8601 date and time' do
          let(:date) { revision.committed_on }
          let(:json_path) { 'createdAt' }
        end
      end

      describe 'authorName' do
        it { is_expected.to have_json_path('authorName') }
        it { is_expected.to be_json_eql('foo bar '.to_json).at_path('authorName') }
      end
    end


    context 'with referencing commit message' do
      let(:work_package) { FactoryGirl.build_stubbed(:work_package, project: project) }
      let(:commit_message) { "Totally references ##{work_package.id}" }
      let(:html_reference) {
        id = work_package.id

        str = "Totally references <a href=\"/work_packages/#{id}\""
        str << " class=\"issue work_package status-1 priority-1 parent\""
        str << " title=\"#{work_package.subject} (#{work_package.status})\">"
        str << "##{id}</a>"
      }

      before do
        allow(WorkPackage).to receive(:find_by_id).and_return(work_package)
      end

      it_behaves_like 'API V3 formattable', 'message' do
        let(:format) { 'plain' }
        let(:raw) { revision.comments }
        let(:html) { '<p>' + html_reference + '</p>' }
      end
    end

    context 'with linked user as author' do
      let(:user) { FactoryGirl.build(:user) }
      before do
        allow(revision).to receive(:user).and_return(user)
      end

      it { is_expected.to have_json_path('_links/author') }
      it { is_expected.to be_json_eql(user.name.to_json).at_path('_links/author/title') }
    end
  end
end
