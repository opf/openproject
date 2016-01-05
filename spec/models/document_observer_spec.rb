#-- copyright
# OpenProject Documents Plugin
#
# Former OpenProject Core functionality extracted into a plugin.
#
# Copyright (C) 2009-2014 the OpenProject Foundation (OPF)
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
require File.dirname(__FILE__) + '/../spec_helper'

describe DocumentObserver do
  let(:user)      { FactoryGirl.create(:user, firstname: 'Test', lastname: "User", mail: 'test@test.com') }
  let(:project)   { FactoryGirl.create(:project, name: "TestProject")}

  let(:mail)      do
    mock = Object.new
    allow(mock).to receive(:deliver_now)
    mock
  end

  it "is triggered, when a document has been created" do
    document = FactoryGirl.build(:document)
    #observers are singletons, so any_instance exactly leaves out the singleton
    expect(DocumentObserver.instance).to receive(:after_create)
    document.save!
  end

  it "calls the DocumentsMailer, when a new document has been added" do
    document = FactoryGirl.build(:document)
    # make sure, that we have actually someone to notify
    allow(document).to receive(:recipients).and_return([user])
    # ... and notifies are actually sent out
    Setting.notified_events = Setting.notified_events << 'document_added'
    expect(DocumentsMailer).to receive(:document_added).and_return(mail)

    document.save
  end
end
