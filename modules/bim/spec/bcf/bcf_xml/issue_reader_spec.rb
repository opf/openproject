#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::OpenProject::Bim::BcfXml::IssueReader do
  let(:absolute_file_path) { "63E78882-7C6A-4BF7-8982-FC478AFB9C97/markup.bcf" }
  let(:type) { FactoryBot.create :type, name: 'Issue', is_standard: true, is_default: true }
  let(:project) do
    FactoryBot.create(:project,
                      identifier: 'bim_project',
                      types: [type])
  end
  let(:manage_bcf_role) do
    FactoryBot.create(
      :role,
      permissions: %i[manage_bcf view_linked_issues view_work_packages edit_work_packages add_work_packages]
    )
  end
  let(:bcf_manager) { FactoryBot.create(:user) }
  let(:workflow) do
    FactoryBot.create(:workflow_with_default_status,
                      role: manage_bcf_role,
                      type: type)
  end
  let(:priority) { FactoryBot.create :default_priority }
  let(:bcf_manager_member) do
    FactoryBot.create(:member,
                      project: project,
                      user: bcf_manager,
                      roles: [manage_bcf_role])
  end
  let(:markup) do
    <<-MARKUP
    <Markup xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <Topic Guid="63E78882-7C6A-4BF7-8982-FC478AFB9C97" TopicType="Issue" TopicStatus="Open">
        <Title>Maximum Content</Title>
        <Priority>High</Priority>
        <Index>0</Index>
        <Labels>Structural</Labels>
        <Labels>IT Development</Labels>
        <CreationDate>2015-06-21T12:00:00Z</CreationDate>
        <CreationAuthor>mike@example.com</CreationAuthor>
        <ModifiedDate>2015-06-21T14:22:47Z</ModifiedDate>
        <ModifiedAuthor>mike@example.com</ModifiedAuthor>
        <AssignedTo>andy@example.com</AssignedTo>
        <Description>This is a topic with all information present.</Description>
        <RelatedTopic Guid="5019D939-62A4-45D9-B205-FAB602C98FE8" />
      </Topic>
      <Comment Guid="780FAE52-C432-42BE-ADEA-FF3E7A8CD8E1">
        <Date>2015-08-31T12:40:17Z</Date>
        <Author>mike@example.com</Author>
        <Comment>This is an unmodified topic at the uppermost hierarchical level.
    All times in the XML are marked as UTC times.</Comment>
      </Comment>
    </Markup>
    MARKUP
  end
  let(:entry) do
    Struct
      .new(:name, :get_input_stream)
      .new(absolute_file_path, entry_stream)
  end
  let(:entry_stream) { StringIO.new(markup) }
  let(:import_options) { OpenProject::Bim::BcfXml::Importer::DEFAULT_IMPORT_OPTIONS }

  subject do
    described_class.new(project,
                        nil,
                        entry,
                        current_user: bcf_manager,
                        import_options: import_options)
  end

  before do
    workflow
    priority
    bcf_manager_member
    allow(User).to receive(:current).and_return(bcf_manager)
  end

  context 'on initial import' do
    let(:bcf_issue) { subject.extract! }

    context 'with happy path, everything has a match' do
      it 'WP start date gets initialized with BCF CreationDate' do
        expect(bcf_issue.work_package.start_date).to eql(subject.extractor.creation_date.to_date)
      end

      it 'Bim::Bcf::Issue get initialized with the GUID form the XML file' do
        expect(bcf_issue.uuid).to eql("63E78882-7C6A-4BF7-8982-FC478AFB9C97")
      end
    end

    context 'Topic does not provide any title, status, type or priority' do
      let(:markup) do
        <<-MARKUP
        <Markup xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
          <Topic Guid="63E78882-7C6A-4BF7-8982-FC478AFB9C97">
            <Title></Title>
            <CreationDate>2015-06-21T12:00:00Z</CreationDate>
            <ModifiedDate>2015-04-21T12:00:00Z</ModifiedDate>
            <CreationAuthor>mike@example.com</CreationAuthor>
          </Topic>
        </Markup>
        MARKUP
      end

      context 'with no import options provided' do
        let(:bcf_issue) { subject.extract! }

        it 'sets a status' do
          expect(bcf_issue.work_package.status).to eql(Status.default)
        end

        it 'sets a type' do
          expect(bcf_issue.work_package.type).to eql(type)
        end

        it 'ignores missing priority' do
          # as it gets set automatically when creating new work packages.
          expect(bcf_issue.work_package.priority).to eql(priority)
        end
      end
    end
  end

  context 'on updating import' do
    context '#update_comment' do
      let(:work_package) { FactoryBot.create(:work_package) }
      let!(:bcf_issue) { FactoryBot.create :bcf_issue_with_comment, work_package: work_package }

      before do
        allow(subject).to receive(:issue).and_return(bcf_issue)
      end

      it '#update_comment' do
        modified_time = Time.now + 1.minute
        comment_data = { uuid: bcf_issue.comments.first.uuid, comment: 'Updated comment', modified_date: modified_time }
        expect(subject).to receive(:update_comment_viewpoint_by_uuid)

        subject.send(:update_comment, comment_data)

        expect(bcf_issue.comments.first.journal.notes).to eql('Updated comment')
        expect(bcf_issue.comments.first.journal.created_at.utc.to_s).to eql(modified_time.utc.to_s)
      end

      it '#update_comment_viewpoint_by_uuid' do
        bcf_comment = bcf_issue.comments.first
        viewpoint = bcf_comment.viewpoint
        bcf_comment.viewpoint = nil

        subject.send(:update_comment_viewpoint_by_uuid, bcf_comment, viewpoint.uuid)
        expect(bcf_comment.viewpoint_id).to eql(viewpoint.id)

        subject.send(:update_comment_viewpoint_by_uuid, bcf_comment, nil)
        expect(bcf_comment.viewpoint).to be_nil
      end

      it '#viewpoint_by_uuid' do
        expect(subject.send(:viewpoint_by_uuid, nil)).to be_nil
        expect(subject.send(:viewpoint_by_uuid, bcf_issue.comments.first.viewpoint.uuid)).to eql(bcf_issue.comments.first.viewpoint)
      end
    end
  end
end
