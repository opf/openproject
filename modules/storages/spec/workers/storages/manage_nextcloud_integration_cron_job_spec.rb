#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe Storages::ManageNextcloudIntegrationCronJob, type: :job do
  it 'has a schedule set' do
    expect(described_class.cron_expression).to eq('*/5 * * * *')
  end

  describe '#perform' do
    subject { described_class.new.perform }

    it 'works out silently' do
      allow(Storages::NextcloudStorage).to receive(:sync_all_group_folders).and_return(true)
      subject
    end

    it 'works out silently without doing anything when sync has been started by another process' do
      allow(Storages::NextcloudStorage).to receive(:sync_all_group_folders).and_return(false)
      subject
    end
  end
end
