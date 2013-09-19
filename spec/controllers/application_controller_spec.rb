#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe ApplicationController do
  let(:user) { FactoryGirl.create(:user, :lastname => "Crazy! Name with \r\n Newline") }

  # Fake controller to test calling an action
  controller do
    def index
      # just do anything that doesn't require an extra template
      render_404
    end
  end

  describe 'with log_requesting_user enabled' do
    before do
      Setting.stub(:log_requesting_user?).and_return(true)
    end

    it 'should log the current user' do
      messages = []
      Rails.logger.should_receive(:info).at_least(:once) do |message|
        messages << message
      end

      as_logged_in_user(user) do
        get(:index)
      end

      filtered_messages = messages.select { |message| message.start_with? 'OpenProject User' }
      filtered_messages.length.should == 1
      filtered_messages[0].should == "OpenProject User: #{user.firstname} Crazy! Name with \#\# " +
                                     "Newline (#{user.login} ID: #{user.id} <#{user.mail}>)"
    end

    it 'should log an anonymous user' do
      messages = []
      Rails.logger.should_receive(:info).at_least(:once) do |message|
        messages << message
      end

      # no login, so this is done as Anonymous
      get(:index)

      filtered_messages = messages.select { |message| message.start_with? 'OpenProject User' }
      filtered_messages.length.should == 1
      filtered_messages[0].should == "OpenProject User: Anonymous"
    end
  end
  describe 'with log_requesting_user disabled' do
    before do
      Setting.stub(:log_requesting_user?).and_return(false)
    end

    it 'should not log the current user' do
      messages = []
      Rails.logger.stub(:info) do |message|
        messages << message
      end

      as_logged_in_user(user) do
        get(:index)
      end

      filtered_messages = messages.select { |message| message.start_with? 'OpenProject User' }
      filtered_messages.length.should == 0
    end
  end
end
