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
require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe Document do
  let(:documentation_category) { create(:document_category, name: "User documentation") }
  let(:project)                { create(:project) }
  let(:user)                   { create(:user) }
  let(:admin)                  { create(:admin) }

  let(:mail) do
    mock = Object.new
    allow(mock).to receive(:deliver_now)
    mock
  end

  context "validation" do
    it { is_expected.to validate_presence_of :project }
    it { is_expected.to validate_presence_of :title }
    it { is_expected.to validate_presence_of :category }
  end

  describe "create with a valid document" do
    let(:valid_document) { Document.new(title: "Test", project:, category: documentation_category) }

    it "adds a document" do
      expect  do
        valid_document.save
      end.to change { Document.count }.by 1
    end

    it "sets a default-category, if none is given" do
      default_category = create(:document_category, name: "Technical documentation", is_default: true)
      document = Document.new(project:, title: "New Document")
      expect(document.category).to eql default_category
      expect do
        document.save
      end.to change { Document.count }.by 1
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
