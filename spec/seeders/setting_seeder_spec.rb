#-- encoding: UTF-8
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

describe 'SettingSeeder' do
  subject { ::BasicData::SettingSeeder.new }

  let(:new_project_role) { Role.find_by(name: I18n.t(:default_role_project_admin)) }
  let(:closed_status) { Status.find_by(name: I18n.t(:default_status_closed)) }

  before do
    allow(STDOUT).to receive(:puts)
    allow(ActionMailer::Base).to receive(:perform_deliveries).and_return(false)
    allow(Delayed::Worker).to receive(:delay_jobs).and_return(false)

    expect { BasicDataSeeder.new.seed! }.not_to raise_error
  end

  def reseed!
    expect(subject).to receive(:update_unless_present).twice.and_call_original
    expect(subject).to be_applicable
    expect { subject.seed! }.not_to raise_error
  end

  shared_examples 'settings' do
    it 'applies initial settings' do
      Setting.where(name: %w(commit_fix_status_id new_project_user_role_id)).delete_all

      reseed!

      expect(Setting.commit_fix_status_id).to eq closed_status.id
      expect(Setting.new_project_user_role_id).to eq new_project_role.id
    end

    it 'does not override settings' do
      Setting.commit_fix_status_id = 1337
      Setting.where(name: 'new_project_user_role_id').delete_all

      reseed!

      expect(Setting.commit_fix_status_id).to eq 1337
      expect(Setting.new_project_user_role_id).to eq new_project_role.id
    end
  end
end
