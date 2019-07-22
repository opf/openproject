#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'spec_helper'

describe ::OpenProject::Bcf::BcfXml::Exporter do
  let(:query) { FactoryBot.build(:global_query)}
  let(:work_package) { FactoryBot.create :work_package }
  let(:admin) { FactoryBot.create(:admin) }
  let(:current_user) { admin }

  before do
    work_package
    allow(User).to receive(:current).and_return current_user
  end

  subject { described_class.new(query) }

  context "one WP without BCF issue associated" do
    it '#work_packages' do
      expect(subject.work_packages.count).to eql(0)
    end
  end

  context "one WP with BCF issue associated" do
    let(:bcf_issue) { FactoryBot.create(:bcf_issue_with_comment, work_package: work_package) }

    before do
      bcf_issue
    end

    it '#work_packages' do
      expect(subject.work_packages.count).to eql(1)
    end
  end
end
