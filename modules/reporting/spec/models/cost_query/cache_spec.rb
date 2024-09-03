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
require File.join(File.dirname(__FILE__), "..", "..", "support", "configuration_helper")

RSpec.describe CostQuery::Cache do
  include OpenProject::Reporting::SpecHelper::ConfigurationHelper

  def all_caches
    [CostQuery::GroupBy::CustomFieldEntries,
     CostQuery::GroupBy,
     CostQuery::Filter::CustomFieldEntries,
     CostQuery::Filter]
  end

  def expect_reset_on_caches
    all_caches.each do |klass|
      expect(klass).to receive(:reset!)
    end
  end

  def expect_no_reset_on_caches
    all_caches.each do |klass|
      expect(klass).not_to receive(:reset!)
    end
  end

  def reset_cache_keys
    # resetting internal caching keys to avoid dependencies with other specs
    described_class.send(:latest_custom_field_change=, nil)
    described_class.send(:custom_field_count=, 0)
  end

  def custom_fields_exist
    allow(WorkPackageCustomField).to receive(:maximum).and_return(Time.now)
    allow(WorkPackageCustomField).to receive(:count).and_return(23)
  end

  def no_custom_fields_exist
    allow(WorkPackageCustomField).to receive(:maximum).and_return(nil)
    allow(WorkPackageCustomField).to receive(:count).and_return(0)
  end

  before do
    reset_cache_keys
  end

  after do
    reset_cache_keys
  end

  describe ".check" do
    context "with cache_classes configuration enabled" do
      before do
        mock_cache_classes_setting_with(true)
      end

      it "resets the caches on filters and group by" do
        custom_fields_exist
        expect_reset_on_caches

        described_class.check
      end

      it "stores when the last update was made and does not reset again if nothing changed" do
        custom_fields_exist
        expect_reset_on_caches

        described_class.check

        expect_no_reset_on_caches

        described_class.check
      end

      it "does reset the cache if last CustomField is removed" do
        custom_fields_exist
        expect_reset_on_caches

        described_class.check

        no_custom_fields_exist
        expect_reset_on_caches

        described_class.check
      end
    end

    context "with_cache_classes configuration disabled" do
      before do
        mock_cache_classes_setting_with(false)
      end

      it "resets the cache again even if nothing changed" do
        custom_fields_exist
        expect_reset_on_caches

        described_class.check

        expect_reset_on_caches

        described_class.check
      end
    end
  end
end
