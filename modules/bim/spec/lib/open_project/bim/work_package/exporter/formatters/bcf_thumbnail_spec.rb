#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe OpenProject::Bim::WorkPackage::Exporter::Formatters::BcfThumbnail do
  describe "::apply?" do
    it "returns TRUE the bcf thumbnail" do
      expect(described_class).to be_apply(:bcf_thumbnail, :whatever)
    end

    it "returns FALSE for any other class" do
      expect(described_class).not_to be_apply(:whatever, :whatever)
    end
  end

  describe "::format" do
    let(:work_package_with_viewpoint) { create(:work_package) }
    let(:bcf_issue) { create(:bcf_issue_with_viewpoint, work_package: work_package_with_viewpoint) }
    let(:work_package_without_viewpoint) { create(:work_package) }

    before do
      bcf_issue
    end

    it 'returns "x" for work packages that have BCF issues with at least one viewpoint' do
      expect(described_class.new(:bcf_thumbnail).format(work_package_with_viewpoint)).to eql("x")
    end

    it 'returns "" for work packages without viewpoints attached' do
      expect(described_class.new(:bcf_thumbnail).format(work_package_without_viewpoint)).to eql("")
    end
  end
end
