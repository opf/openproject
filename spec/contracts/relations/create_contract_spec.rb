#-- encoding: UTF-8
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

describe Relations::CreateContract do
  let(:from) { FactoryGirl.create :work_package }
  let(:to) { FactoryGirl.create :work_package }
  let(:user) { FactoryGirl.create :admin }

  let(:relation) do
    Relation.new from_id: from.id, to_id: to.id, relation_type: "follows", delay: 42
  end

  subject(:contract) { described_class.new relation, user }

  describe "validating the delay" do
    class ::Delayed::DelayProxy
      def to_i
        99
      end
    end

    it "does not trigger delayed_job and checks the correct delay" do
      begin
        expect(contract).to be_valid
        expect(contract.send(:fields).delay.to_i).to eq 42
      ensure
        ::Delayed::DelayProxy.send :remove_method, :to_i
      end
    end
  end
end
