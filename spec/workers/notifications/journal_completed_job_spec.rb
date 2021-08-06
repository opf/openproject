#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Notifications::JournalCompletedJob, type: :model do
  let(:journal) { FactoryBot.build_stubbed(:journal, journable: journable) }

  describe '.supported?' do
    context 'with a work package journal' do
      let(:journable) { FactoryBot.build_stubbed(:stubbed_work_package) }

      it 'is truthy' do
        expect(described_class)
          .to be_supported(journal)
      end
    end

    context 'with a wiki content journal' do
      let(:journable) { FactoryBot.build_stubbed(:wiki_content) }

      it 'is truthy' do
        expect(described_class)
          .to be_supported(journal)
      end
    end

    context 'with a news journal' do
      let(:journable) { FactoryBot.build_stubbed(:news) }

      it 'is falsey' do
        expect(described_class)
          .not_to be_supported(journal)
      end
    end
  end
end
