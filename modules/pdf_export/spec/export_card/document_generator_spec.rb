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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OpenProject::PDFExport::ExportCard::DocumentGenerator do
  let(:config) { ExportCardConfiguration.new({
    name: "Default",
    description: "This is a description",
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        subject:\n          has_label: false\n          font_size: 15\n    row2:\n      height: 50\n      priority: 1\n      columns:\n        non_existent:\n          has_label: true\n          font_size: 15\n          render_if_empty: true"
  })}

  let(:work_package1) { WorkPackage.new({
    subject: "Work package 1",
    description: "This is a description"
  })}

  let(:work_package2) { WorkPackage.new({
    subject: "Work package 2",
    description: "This is work package 2"
  })}

  describe "Single work package rendering" do
    before(:each) do
      work_packages = [work_package1]
      @generator = OpenProject::PDFExport::ExportCard::DocumentGenerator.new(config, work_packages)
    end

    it 'shows work package subject' do
      text_analysis = PDF::Inspector::Text.analyze(@generator.render)
      expect(text_analysis.strings.include?('Work package 1')).to be_truthy
    end

    it 'does not show non existent field label' do
      text_analysis = PDF::Inspector::Text.analyze(@generator.render)
      expect(text_analysis.strings.include?('Non existent:')).to be_falsey
    end

    it 'should be 1 page' do
      page_analysis = PDF::Inspector::Page.analyze(@generator.render)
      expect(page_analysis.pages.size).to eq(1)
    end
  end

  describe "Multiple work package rendering" do
    before(:each) do
      work_packages = [work_package1, work_package2]
      @generator = OpenProject::PDFExport::ExportCard::DocumentGenerator.new(config, work_packages)
    end

    it 'shows work package subject' do
      text = PDF::Inspector::Text.analyze(@generator.render)
      expect(text.strings.include?('Work package 1')).to be_truthy
      expect(text.strings.include?('Work package 2')).to be_truthy
    end

    it 'should be 2 pages' do
      page_analysis = PDF::Inspector::Page.analyze(@generator.render)
      expect(page_analysis.pages.size).to eq(2)
    end
  end

end
