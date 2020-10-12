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

describe DocumentsMailer do

  let(:user) {
    FactoryBot.create(:user, firstname: 'Test', lastname: "User", mail: 'test@test.com')
  }
  let(:project) { FactoryBot.create(:project, name: "TestProject") }
  let(:document) {
    FactoryBot.create(:document, project: project, description: "Test Description", title: "Test Title" )
  }
  let(:mail) { DocumentsMailer.document_added(user, document) }

  describe "document added-mail" do
    it "renders the subject" do
      expect(mail.subject).to eql '[TestProject] New document: Test Title'
    end

    it "should render the receivers mail" do
      expect(mail.to.count).to eql 1
      expect(mail.to.first).to eql user.mail
    end

    it "should render the document-info into the body" do
      expect(mail.body.encoded).to match(document.description)
      expect(mail.body.encoded).to match(document.title)
    end

  end




end
