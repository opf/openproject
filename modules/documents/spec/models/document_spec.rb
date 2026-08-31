# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Document do
  let(:project)                { create(:project) }
  let(:user)                   { create(:user) }
  let(:admin)                  { create(:admin) }

  let(:mail) do
    mock = Object.new
    allow(mock).to receive(:deliver_now)
    mock
  end

  describe "Enums" do
    it do
      expect(subject).to define_enum_for(:kind)
        .with_values(classic: "classic", collaborative: "collaborative")
        .backed_by_column_of_type(:string)
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:type).class_name("DocumentType").optional }
  end

  describe "title normalization" do
    it_behaves_like "strips invisible characters", :title
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of :title }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }
  end

  describe "Database constraints" do
    it { is_expected.to have_db_column(:title).of_sql_type("character varying(255)") }

    it "defaults to 'collaborative' kind" do
      expect(described_class.new).to be_collaborative
    end
  end

  describe "create with a valid document" do
    let(:valid_document) { build(:document, title: "Test", project:) }

    it "adds a document" do
      expect  do
        valid_document.save
      end.to change(described_class, :count).by 1
    end

    it "sets a default type, if none is given" do
      default_type = create(:document_type, name: "Technical documentation", is_default: true)
      document = described_class.new(project:, title: "New Document")
      expect(document.type).to eql default_type
      expect { document.save }.to change(described_class, :count).by 1
    end

    it "with attachments should change the updated_at-date on the document to the attachment's date" do
      valid_document.save

      expect do
        Attachments::CreateService
          .new(user: admin)
          .call(container: valid_document, file: attributes_for(:attachment)[:file], filename: "foo")

        expect(valid_document.attachments.size).to be 1
      end.to(change do
        valid_document.reload
        valid_document.updated_at
      end)
    end

    it "without attachments, the updated-on-date is taken from the document's date" do
      document = create(:document, project:)
      expect(document.attachments).to be_empty
      expect(document.created_at).to eql document.updated_at
    end
  end

  describe "acts as event" do
    let(:now) { Time.zone.now }
    let(:document) do
      build(:document,
            created_at: now)
    end

    it { expect(document.event_datetime.to_i).to eq(now.to_i) }
  end
end
