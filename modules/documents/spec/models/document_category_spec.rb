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
require File.dirname(__FILE__) + '/../spec_helper'


describe DocumentCategory do

  let(:project) {FactoryBot.create(:project)}

  it "should be an enumeration" do
    expect(DocumentCategory.ancestors).to include Enumeration
  end

  it "should order documents by the category they are created with" do
    uncategorized  = FactoryBot.create :document_category, name: "Uncategorized", project: project
    user_documentation = FactoryBot.create :document_category, name: "User documentation"

    FactoryBot.create_list :document, 2, category: uncategorized, project: project

    expect(DocumentCategory.find_by_name(uncategorized.name).objects_count).to eql 2
    expect(DocumentCategory.find_by_name(user_documentation.name).objects_count).to eql 0

  end

  it "should file the categorizations under the option name :enumeration_doc_categories" do
    expect(DocumentCategory.new.option_name).to eql :enumeration_doc_categories
  end

  it "should only allow one category to be the default-category" do
    old_default = FactoryBot.create :document_category, name: "old default", project: project, is_default: true

    expect{
      FactoryBot.create :document_category, name: "new default", project: project, is_default: true
      old_default.reload
    }.to change{old_default.is_default?}.from(true).to(false)


  end

end
