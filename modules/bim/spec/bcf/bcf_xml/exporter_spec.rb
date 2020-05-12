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

describe ::OpenProject::Bim::BcfXml::Exporter do
  let(:query) { FactoryBot.build(:global_query) }
  let(:work_package) { FactoryBot.create :work_package }
  let(:admin) { FactoryBot.create(:admin) }
  let(:current_user) { admin }

  before do
    work_package
    login_as current_user
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
