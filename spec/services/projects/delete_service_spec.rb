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

describe ::Projects::DeleteService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:admin) }
  let(:project) { FactoryBot.build_stubbed(:project) }

  let(:instance) { described_class.new(user: user, model: project) }

  subject { instance.call }

  context 'if authorized' do
    it 'destroys the project and sends a success mail' do
      expect(project).not_to receive(:archive)
      expect(project).to receive(:destroy).and_return true

      expect(ProjectMailer)
        .to receive_message_chain(:delete_project_completed, :deliver_now)

      expect(::Projects::DeleteProjectJob)
        .not_to receive(:new)

      expect(subject).to be_success
    end

    it 'sends a message on destroy failure' do
      expect(project).to receive(:destroy).and_return false

      expect(ProjectMailer)
        .to receive_message_chain(:delete_project_failed, :deliver_now)

      expect(::Projects::DeleteProjectJob)
        .not_to receive(:new)

      expect(subject).to be_failure
    end
  end

  context 'if not authorized' do
    let(:user) { FactoryBot.build_stubbed(:user) }

    it 'returns an error' do
      expect(::Projects::DeleteProjectJob)
        .not_to receive(:new)

      expect(subject).to be_failure
    end
  end
end
