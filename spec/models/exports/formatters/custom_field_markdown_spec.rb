# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Exports::Formatters::CustomFieldMarkdown do
  let(:bool_cf) { create(:issue_custom_field, :boolean, is_for_all: true) }
  let(:date_cf) { create(:issue_custom_field, :date, is_for_all: true) }
  let(:datetime_cf) { create(:issue_custom_field, :datetime, is_for_all: true) }
  let(:link_cf) { create(:issue_custom_field, :link, is_for_all: true) }
  let(:type) { create(:type, custom_fields: [bool_cf, date_cf, datetime_cf, link_cf]) }
  let(:project) { create(:project, types: [type]) }
  let(:work_package) do
    create(:work_package, project:, type:,
                          custom_field_values: {
                            bool_cf.id => true,
                            date_cf.id => "2024-05-30",
                            datetime_cf.id => "2024-05-30T12:30:00Z",
                            link_cf.id => "https://example.com"
                          })
  end

  def format(custom_field)
    described_class.new("cf_#{custom_field.id}").format(work_package.reload)
  end

  it { expect(described_class.apply?("cf_1", :md)).to be(true) }
  it { expect(described_class.apply?("cf_1", :csv)).to be(false) }
  it { expect(described_class.apply?("status", :md)).to be(false) }

  it "prints booleans as Yes/No" do
    expect(format(bool_cf)).to eq(I18n.t(:general_text_Yes))
  end

  it "prints unset booleans as No" do
    work_package.update!(custom_field_values: { bool_cf.id => false })
    expect(format(bool_cf)).to eq(I18n.t(:general_text_No))
  end

  it "prints dates in ISO 8601" do
    expect(format(date_cf)).to eq("2024-05-30")
  end

  it "prints datetimes in ISO 8601" do
    expect(format(datetime_cf)).to eq(Time.utc(2024, 5, 30, 12, 30).iso8601)
  end

  it "prints link fields as the bare URL" do
    expect(format(link_cf)).to eq("https://example.com")
  end

  it "is the formatter the registry resolves for :md" do
    expect(Exports::Register.formatter_for(WorkPackage, "cf_#{bool_cf.id}", :md)).to be_a(described_class)
  end

  it "leaves :csv to the generic custom field formatter" do
    expect(Exports::Register.formatter_for(WorkPackage, "cf_#{bool_cf.id}", :csv))
      .to be_an_instance_of(Exports::Formatters::CustomField)
  end
end
