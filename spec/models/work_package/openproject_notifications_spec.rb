#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

##
# Tests that email notifications will be sent upon creating or changing a work package.
describe WorkPackage, type: :model do
  describe 'OpenProject notifications' do
    let(:user) { FactoryBot.create :admin }
    let(:current_user) { FactoryBot.create :admin }
    let(:project) { FactoryBot.create :project }
    let(:work_package) do
      FactoryBot.create :work_package,
                         author: user,
                         subject: 'I can see you',
                         project: project
    end

    let(:journal_ids) { [] }

    before do
      OpenProject::Notifications.subscribe(OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY) do |payload|
        journal_ids << payload[:journal_id]
      end
    end

    context 'after creation' do
      before do
        work_package
      end

      it "are triggered" do
        expect(journal_ids).to include (work_package.journals.last.id)
      end
    end

    describe 'after update' do
      before do
        work_package

        journal_ids.clear

        work_package.update_attributes subject: 'the wind of change'
      end

      it "are triggered" do
        expect(journal_ids).to include (work_package.journals.last.id)
      end
    end
  end
end
