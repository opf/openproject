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
require File.dirname(__FILE__) + '/../spec_helper'

describe Document do
  let(:documentation_category) { FactoryBot.create :document_category, name: 'User documentation'}
  let(:project)                { FactoryBot.create :project}
  let(:user)                   { FactoryBot.create(:user)}
  let(:admin)                  { FactoryBot.create(:admin)}

  let(:mail) do
    mock = Object.new
    allow(mock).to receive(:deliver_now)
    mock
  end

  context "validation" do
    it { is_expected.to validate_presence_of :project}
    it { is_expected.to validate_presence_of :title}
    it { is_expected.to validate_presence_of :category}
  end

  describe "create with a valid document" do
    let(:valid_document) {Document.new(title: "Test", project: project, category: documentation_category)}

    it "should add a document" do
      expect{
        valid_document.save
      }.to change{Document.count}.by 1
    end

    it "should send out email-notifications" do
      allow(valid_document).to receive(:recipients).and_return([user])
      Setting.notified_events = Setting.notified_events << 'document_added'

      expect{
        valid_document.save
      }.to change{ActionMailer::Base.deliveries.size}.by 1
    end

    it "should send notifications to the recipients of the project" do
      allow(project).to receive(:notified_users).and_return([admin])
      document = FactoryBot.create(:document, project: project)

      expect(document.recipients).not_to be_empty
      expect(document.recipients.count).to eql 1
      expect(document.recipients.map(&:mail)).to include admin.mail
    end

    it "should set a default-category, if none is given" do
      default_category = FactoryBot.create :document_category, name: 'Technical documentation', is_default: true
      document = Document.new(project: project, title: "New Document")
      expect(document.category).to eql default_category
      expect{
        document.save
      }.to change { Document.count }.by 1
    end

    it "with attachments should change the updated_on-date on the document to the attachment's date" do
      3.times do
        FactoryBot.create(:attachment, container: valid_document)
      end

      valid_document.reload
      expect(valid_document.attachments.size).to eql 3
      expect(valid_document.attachments.map(&:created_at).max).to eql valid_document.updated_on
    end

    it "without attachments, the updated-on-date is taken from the document's date" do
      document = FactoryBot.create(:document, project: project)
      expect(document.attachments).to be_empty
      expect(document.created_at).to eql document.updated_at
    end
  end

  describe "acts as event" do
    let(:now) { Time.zone.now }
    let(:document) do
      FactoryBot.build(:document,
                       created_at: now)
    end

    it { expect(document.event_datetime.to_i).to eq(now.to_i) }
  end

  it "calls the DocumentsMailer, when a new document has been added" do
    document = FactoryBot.build(:document)
    # make sure, that we have actually someone to notify
    allow(document).to receive(:recipients).and_return([user])
    # ... and notifies are actually sent out
    Setting.notified_events = Setting.notified_events << 'document_added'
    expect(DocumentsMailer).to receive(:document_added).and_return(mail)

    document.save
  end
end
