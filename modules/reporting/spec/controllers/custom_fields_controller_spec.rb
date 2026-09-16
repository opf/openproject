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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe CustomFieldsController do
  let!(:custom_field) { create(:work_package_custom_field) }
  let!(:custom_field_permanent) { create(:work_package_custom_field) }
  let(:attribute) { custom_field.column_name }
  let(:permanent_attribute) { custom_field_permanent.column_name }

  let(:report) { create(:cost_report) }
  let(:query) { report.query }

  before do
    allow(@controller).to receive(:authorize)
    allow(@controller).to receive(:check_if_login_required)
    allow(@controller).to receive(:require_admin)
  end

  def filter_for(name)
    query.filter_for(name).tap do |filter|
      filter.operator = "="
      filter.values = ["t"]
    end
  end

  describe "#destroy" do
    subject { report.reload }

    before do
      query.filters = [filter_for(attribute), filter_for(permanent_attribute)]
      report.apply_pivot_configuration(rows: [attribute], columns: [permanent_attribute])
      report.save!

      delete :destroy, params: { id: custom_field.id }
    end

    it "removes the custom field from the report's axes" do
      expect(subject.pivot_rows).to eq []
      expect(subject.pivot_columns).to eq [permanent_attribute]
    end

    it "removes the custom field from the query's filters" do
      expect(subject.query.filters.map { |filter| filter.name.to_s }).to eq [permanent_attribute]
    end

    it "keeps the query's group_bys in sync with the axes" do
      expect(subject.query.group_bys.map { |group_by| group_by.name.to_s }).to eq [permanent_attribute]
    end
  end
end
