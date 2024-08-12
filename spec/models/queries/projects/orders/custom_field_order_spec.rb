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

RSpec.describe Queries::Projects::Orders::CustomFieldOrder do
  let!(:cf_text) { FactoryBot.create(:text_project_custom_field) }
  let!(:cf_int) { FactoryBot.create(:integer_project_custom_field) }

  before do
    allow(User).to receive(:current).and_return build_stubbed(:admin)
  end

  it "does not allow to sort by the text field" do
    cf = described_class.new("cf_#{cf_text.id}")
    expect(cf).not_to be_available
  end

  it "allows to sort by all other fields" do
    cf = described_class.new("cf_#{cf_int.id}")
    expect(cf).to be_available
  end
end
