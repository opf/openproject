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

describe ::OpenProject::Bim::BcfXml::DelayedExporter do
  let(:ids) { [1, 2, 3] }
  let(:query) do
    FactoryBot.build_stubbed(:query).tap do |q|
      allow(q)
        .to receive_message_chain(:results, :sorted_work_packages, :pluck)
        .and_return ids
    end
  end
  let(:current_user) { FactoryBot.build_stubbed(:user) }

  subject { described_class.new(query) }

  before do
    login_as current_user
  end

  describe '#list' do
    it 'returns a delayed result' do
      subject.list do |result|
        expect(result)
          .to be_delayed
      end
    end

    it 'creates a delayed export' do
      expect { subject.list {} }
        .to change { WorkPackages::Export.count }
        .by 1
    end

    it 'returns the id of the delayed export' do
      subject.list do |result|
        expect(WorkPackages::Export.exists?(result.id))
          .to be_truthy
      end
    end

    it 'creates a delayed job for actual extraction' do
      export = double('work package export', id: 6)
      allow(WorkPackages::Export)
        .to receive(:create)
        .with(user: current_user)
        .and_return(export)

      expect(Bim::Bcf::ExportJob)
        .to receive(:perform_later)
        .with(user: current_user,
              export: export,
              work_package_ids: ids)

      subject.list {}
    end
  end
end
