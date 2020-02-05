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

describe Relations::CreateContract do
  let(:from) { FactoryBot.build_stubbed :work_package }
  let(:to) { FactoryBot.build_stubbed :work_package }
  let(:user) { FactoryBot.build_stubbed :admin }

  let(:relation) do
    Relation.new from: from, to: to, relation_type: "follows", delay: 42
  end

  subject(:contract) { described_class.new relation, user }

  before do
    allow(WorkPackage)
      .to receive_message_chain(:visible, :exists?)
      .and_return(true)
  end

  describe 'to' do
    context 'not visible' do
      before do
        allow(WorkPackage)
          .to receive_message_chain(:visible, :exists?)
          .with(to.id)
          .and_return(false)
      end

      it 'is invalid' do
        is_expected.not_to be_valid
      end
    end
  end

  describe 'from' do
    context 'not visible' do
      before do
        allow(WorkPackage)
          .to receive_message_chain(:visible, :exists?)
          .with(from.id)
          .and_return(false)
      end

      it 'is invalid' do
        is_expected.not_to be_valid
      end
    end
  end
end
