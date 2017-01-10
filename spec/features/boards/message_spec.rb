#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'messages', type: :feature do
  let(:user) { FactoryGirl.create :admin, firstname: 'Hugo', lastname: 'Hungrig' }

  before do
    allow(User).to receive(:current).and_return user
  end

  describe 'quoting' do
    let(:topic) { FactoryGirl.create :message }
    let!(:reply) do
      FactoryGirl.create :message,
                         board: topic.board,
                         parent: topic,
                         author: user,
                         subject: 'Go Ahead!',
                         content: 'You can quote me on this!'
    end

    before do
      visit topic_path(topic)
    end

    describe 'clicking on quote', js: true do
      it 'opens the filled-in reply form' do
        msg = find 'div.reply', text: /Go Ahead!/
        within(msg) do click_on 'Quote' end

        reply = find '#reply'
        expect(reply).to be_visible

        subject = find '#reply_subject'
        expect(subject.value).to eq 'RE: Go Ahead!'

        content = find '#reply_content'
        expect(content.value).to eq "Hugo Hungrig wrote:\n> You can quote me on this!\n\n"
      end
    end
  end
end
