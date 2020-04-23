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

describe ::OpenProject::Bim::BcfXml::IssueWriter do
  let(:project) { FactoryBot.create(:project) }
  let(:markup) do
    <<-MARKUP
    <Markup xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <Header>
        <File IfcProject="0M6o7Znnv7hxsbWgeu7oQq" IfcSpatialStructureElement="23B$bNeGHFQuMYJzvUX0FD" isExternal="false">
          <Filename>IfcPile_01.ifc</Filename>
          <Date>2014-10-27T16:27:27Z</Date>
          <Reference>../IfcPile_01.ifc</Reference>
        </File>
      </Header>
      <Topic Guid="63E78882-7C6A-4BF7-8982-FC478AFB9C97" TopicType="Structural" TopicStatus="Open">
        <ReferenceLink>https://bim--it.net</ReferenceLink>
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
        <BimSnippet SnippetType="JSON">
          <Reference>JsonElement.json</Reference>
          <ReferenceSchema>http://json-schema.org</ReferenceSchema>
        </BimSnippet>
        <DocumentReference isExternal="true">
          <ReferencedDocument>https://github.com/BuildingSMART/BCF-XML</ReferencedDocument>
          <Description>GitHub BCF Specification</Description>
        </DocumentReference>
        <DocumentReference>
          <ReferencedDocument>../markup.xsd</ReferencedDocument>
          <Description>Markup.xsd Schema</Description>
        </DocumentReference>
        <RelatedTopic Guid="5019D939-62A4-45D9-B205-FAB602C98FE8" />
      </Topic>
      <Viewpoints Guid="8dc86298-9737-40b4-a448-98a9e953293a">
        <Viewpoint>Viewpoint_8dc86298-9737-40b4-a448-98a9e953293a.bcfv</Viewpoint>
        <Snapshot>Snapshot_8dc86298-9737-40b4-a448-98a9e953293a.png</Snapshot>
      </Viewpoints>
      <Viewpoints Guid="21dd4807-e9af-439e-a980-04d913a6b1ce">
        <Viewpoint>Viewpoint_21dd4807-e9af-439e-a980-04d913a6b1ce.bcfv</Viewpoint>
        <Snapshot>Snapshot_21dd4807-e9af-439e-a980-04d913a6b1ce.png</Snapshot>
      </Viewpoints>
      <Viewpoints Guid="81daa431-bf01-4a49-80a2-1ab07c177717">
        <Viewpoint>Viewpoint_81daa431-bf01-4a49-80a2-1ab07c177717.bcfv</Viewpoint>
        <Snapshot>Snapshot_81daa431-bf01-4a49-80a2-1ab07c177717.png</Snapshot>
      </Viewpoints>
    </Markup>
    MARKUP
  end
  let(:bcf_issue) do
    FactoryBot.create(:bcf_issue_with_comment,
                      work_package: work_package,
                      markup: markup)
  end
  let(:priority) { FactoryBot.create :priority_low }
  let(:current_user) { FactoryBot.create(:user) }
  let(:due_date) { DateTime.now }
  let(:type) { FactoryBot.create :type, name: 'Issue' }
  let(:work_package) do
    FactoryBot.create(:work_package,
                      project_id: project.id,
                      priority: priority,
                      author: current_user,
                      assigned_to: current_user,
                      due_date: due_date,
                      type: type)
  end

  before do
    allow(User).to receive(:current).and_return current_user

    bcf_issue.comments.first.journal.update_attribute('journable_id', work_package.id)
    FactoryBot.create(:work_package_journal, notes: "Some note created in OP.", journable_id: work_package.id)
  end

  shared_examples_for "writes Topic" do
    it "updates the Topic node" do
      work_package.reload

      expect(subject.at('Markup')).to be_present
      expect(subject.at('Topic')).to be_present

      expect(subject.at('Topic/@Guid').content).to be_eql bcf_issue.uuid
      expect(subject.at('Topic/@TopicStatus').content).to be_eql work_package.status.name
      expect(subject.at('Topic/@TopicType').content).to be_eql 'Issue'

      expect(subject.at('Topic/Title').content).to be_eql work_package.subject
      expect(subject.at('Topic/CreationDate').content).to be_eql work_package.created_at.iso8601
      expect(subject.at('Topic/ModifiedDate').content).to be_eql work_package.updated_at.iso8601
      expect(subject.at('Topic/Description').content).to be_eql work_package.description
      expect(subject.at('Topic/CreationAuthor').content).to be_eql work_package.author.mail
      expect(subject.at('Topic/ReferenceLink').content).to be_eql url_helpers.work_package_url(work_package)
      expect(subject.at('Topic/Priority').content).to be_eql work_package.priority.name
      expect(subject.at('Topic/ModifiedAuthor').content).to be_eql work_package.journals.last.user.mail
      expect(subject.at('Topic/AssignedTo').content).to be_eql work_package.assigned_to.mail
      expect(subject.at('Topic/DueDate').content).to be_eql work_package.due_date.to_datetime.iso8601
    end
  end

  def valid_markup?(doc)
    schema = Nokogiri::XML::Schema(File.read(File.join(Rails.root, 'modules/bim/spec/bcf/bcf_xml/markup.xsd')))
    errors = schema.validate(doc)
    if errors.empty?
      true
    else
      puts errors.map(&:message).join("\n")
      false
    end
  end

  shared_examples_for 'valid markup' do
    it 'produces valid markup' do
      expect(valid_markup? subject).to be_truthy
    end
  end

  context 'no markup present yet' do
    let(:markup) { nil }

    subject { Nokogiri::XML(described_class.update_from!(work_package).markup) }

    it_behaves_like 'writes Topic'
    it_behaves_like 'valid markup'
  end

  context 'markup already present' do
    subject { Nokogiri::XML(described_class.update_from!(work_package).markup) }

    it_behaves_like 'writes Topic'
    it_behaves_like 'valid markup'

    it "maintains existing nodes and attributes untouched" do
      expect(subject.at('Index').content).to be_eql "0"
      expect(subject.at('BimSnippet')['SnippetType']).to be_eql "JSON"
    end

    it 'it exports all BCF comments' do
      expect(subject.at('/Markup/Comment[1]/Comment').content).to eql("Some BCF comment.")
    end

    it 'creates BCF comments for comments that were created within OP.' do
      expect(subject.at('/Markup/Comment[2]/Comment').content).to eql("Some note created in OP.")
      expect(Bim::Bcf::Comment.count).to eql(2)
    end

    it 'replaces the BCF viewpoints names to use its uuid only' do
      uuid = bcf_issue.viewpoints.first.uuid
      viewpoint_node = subject.at("/Markup/Viewpoints[@Guid='#{uuid}']")
      expect(viewpoint_node.at('Viewpoint').content).to eql("#{uuid}.xml")
      expect(viewpoint_node.at('Snapshot').content).to eql("#{uuid}.jpg")
    end
  end

  def url_helpers
    @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
  end
end
