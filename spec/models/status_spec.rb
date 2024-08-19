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

RSpec.describe Status do
  let(:stubbed_status) { build_stubbed(:status) }

  describe "default status" do
    context "when default exists" do
      let!(:status) { create(:default_status) }

      it "returns that one" do
        expect(described_class.default).to eq(status)
        expect(described_class.where_default.pluck(:id)).to eq([status.id])
      end

      it "can not be set read only (Regression #33750)", with_ee: %i[readonly_work_packages] do
        status.is_readonly = true
        expect(status.save).to be false
        expect(status.errors[:is_readonly]).to include(I18n.t("activerecord.errors.models.status.readonly_default_exlusive"))
      end

      it "is removed from the existing default status upon creation of a new one" do
        new_default = create(:status)
        new_default.is_default = true
        new_default.save

        expect(status.reload)
          .not_to be_is_default
      end
    end

    it "is not true by default" do
      status = described_class.new name: "Status"

      expect(status)
        .not_to be_is_default
    end
  end

  describe "#is_readonly" do
    let!(:status) { build(:status, is_readonly: true) }

    context "when EE enabled", with_ee: %i[readonly_work_packages] do
      it "is still marked read only" do
        expect(status.is_readonly).to be_truthy
        expect(status).to be_is_readonly
      end
    end

    context "when EE no longer enabled", with_ee: false do
      it "is still marked read only" do
        expect(status.is_readonly).to be_falsey
        expect(status).not_to be_is_readonly

        # But DB attribute is still correct to keep the state
        # whenever user reactivates
        expect(status.read_attribute(:is_readonly)).to be_truthy
      end
    end
  end

  describe "#cache_key" do
    it "updates when the updated_at field changes" do
      old_cache_key = stubbed_status.cache_key

      stubbed_status.updated_at = Time.zone.now

      expect(stubbed_status.cache_key)
        .not_to eql old_cache_key
    end
  end

  describe "#destroy" do
    it "cannot be destroyed if the status is in use" do
      work_package = create(:work_package)

      expect { work_package.status.destroy }
        .to raise_error(RuntimeError, "Can't delete status")
    end

    it "cleans up the workflows" do
      workflow = create(:workflow)

      expect { workflow.old_status.destroy }
        .to change { Workflow.exists?(id: workflow.id) }
              .from(true)
              .to(false)
    end
  end
end
