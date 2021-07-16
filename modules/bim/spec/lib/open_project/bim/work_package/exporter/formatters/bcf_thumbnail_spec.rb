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

describe OpenProject::Bim::WorkPackage::Exporter::Formatters::BcfThumbnail do
  let(:bcf_thumbnail_column) { ::Bim::Queries::WorkPackages::Columns::BcfThumbnailColumn.new("Some column name") }
  let(:not_bcf_thumbnail_column) { "This not a BcfThumbnailColumn" }

  describe '::apply?' do
    it 'returns TRUE for any other class' do
      expect(described_class.apply?(bcf_thumbnail_column)).to be_truthy
    end

    it 'returns FALSE for any other class' do
      expect(described_class.apply?(not_bcf_thumbnail_column)).to be_falsey
    end
  end

  describe '::format' do
    let(:work_package_with_viewpoint) { FactoryBot.create(:work_package) }
    let(:bcf_issue) { FactoryBot.create(:bcf_issue_with_viewpoint, work_package: work_package_with_viewpoint) }
    let(:work_package_without_viewpoint) { FactoryBot.create(:work_package) }

    before do
      bcf_issue
    end

    it 'returns "x" for work packages that have BCF issues with at least one viewpoint' do
      expect(described_class.new.format(work_package_with_viewpoint, bcf_thumbnail_column)).to eql('x')
    end

    it 'returns "" for work packages without viewpoints attached' do
      expect(described_class.new.format(work_package_without_viewpoint, bcf_thumbnail_column)).to eql('')
    end
  end
end

