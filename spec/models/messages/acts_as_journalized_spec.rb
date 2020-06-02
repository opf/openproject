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

describe Message, 'acts_as_journalized', type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }
  let!(:forum) do
    FactoryBot.create(:forum,
                      project: project)
  end
  let(:attachment) { FactoryBot.create(:attachment, container: nil, author: user) }

  context 'on creation' do
    context 'attachments' do
      before do
        Message.create! forum: forum, subject: 'Test message', content: 'Message body', attachments: [attachment]
      end
      let(:attachment_id) { "attachments_#{attachment.id}" }
      let(:filename) { attachment.filename }

      subject { Message.last.journals.last.details }

      it { is_expected.to have_key attachment_id }

      it { expect(subject[attachment_id]).to eq([nil, filename]) }
    end
  end
end
