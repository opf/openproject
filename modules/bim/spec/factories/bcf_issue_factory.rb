#-- encoding: UTF-8

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

FactoryBot.define do
  factory :bcf_issue, class: ::Bim::Bcf::Issue do
    markup do
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
        <ModifiedAuthor>michelle@example.com</ModifiedAuthor>
        <AssignedTo>andy@example.com</AssignedTo>
        <Description>This is a topic with all information present.</Description>
        <Stage>Construction start</Stage>
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
      <Comment Guid="780FAE52-C432-42BE-ADEA-FF3E7A8CD8E1">
        <Date>2015-08-31T12:40:17Z</Date>
        <Author>mike@example.com</Author>
        <Comment>This is an unmodified topic at the uppermost hierarchical level.
    All times in the XML are marked as UTC times.</Comment>
      </Comment>
      <Comment Guid="897E4909-BDF3-4CC7-A283-6506CAFF93DD">
        <Date>2015-08-31T14:00:01Z</Date>
        <Author>mike@example.com</Author>
        <Comment>This comment was a reply to the first comment in BCF v2.0. This is a no longer supported functionality and therefore is to be treated as a regular comment in v2.1.</Comment>
      </Comment>
      <Comment Guid="39C4B780-1B48-44E5-9802-D359007AA44E">
        <Date>2015-08-31T13:07:11Z</Date>
        <Author>mike@example.com</Author>
        <Comment>This comment again is in the highest hierarchy level.
    It references a viewpoint.</Comment>
        <Viewpoint Guid="8dc86298-9737-40b4-a448-98a9e953293a" />
      </Comment>
      <Comment Guid="BD17158C-4267-4433-98C1-904F9B41CA50">
        <Date>2015-08-31T15:42:58Z</Date>
        <Author>mike@example.com</Author>
        <Comment>This comment contained some spllng errs.
    Hopefully, the modifier did catch them all.</Comment>
        <ModifiedDate>2015-08-31T16:07:11Z</ModifiedDate>
        <ModifiedAuthor>mike@example.com</ModifiedAuthor>
      </Comment>
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
    stage { nil }
    labels { [] }
    sequence(:index) { |n| n }

    factory :bcf_issue_with_viewpoint do
      after(:create) do |issue|
        create(:bcf_viewpoint, issue: issue)
      end
    end

    factory :bcf_issue_with_comment do
      after(:create) do |issue|
        viewpoint = create(:bcf_viewpoint, issue: issue)
        create(:bcf_comment, issue: issue, viewpoint: viewpoint)
      end
    end
  end
end
