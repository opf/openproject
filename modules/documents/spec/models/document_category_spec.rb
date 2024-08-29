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
require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe DocumentCategory do
  let(:project) { create(:project) }

  it "is an enumeration" do
    expect(DocumentCategory.ancestors).to include Enumeration
  end

  it "orders documents by the category they are created with" do
    uncategorized = create(:document_category, name: "Uncategorized", project:)
    user_documentation = create(:document_category, name: "User documentation")

    create_list(:document, 2, category: uncategorized, project:)

    expect(DocumentCategory.find_by_name(uncategorized.name).objects_count).to be 2
    expect(DocumentCategory.find_by_name(user_documentation.name).objects_count).to be 0
  end

  it "files the categorizations under the option name :enumeration_doc_categories" do
    expect(DocumentCategory.new.option_name).to be :enumeration_doc_categories
  end

  it "onlies allow one category to be the default-category" do
    old_default = create(:document_category, name: "old default", project:, is_default: true)

    expect do
      create(:document_category, name: "new default", project:, is_default: true)
      old_default.reload
    end.to change { old_default.is_default? }.from(true).to(false)
  end
end
