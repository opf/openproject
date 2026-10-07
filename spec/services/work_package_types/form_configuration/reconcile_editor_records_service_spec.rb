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

RSpec.describe WorkPackageTypes::FormConfiguration::ReconcileEditorRecordsService do
  subject(:reconcile) { described_class.new(form).call }

  let(:form) { create(:form_configuration) }

  context "with a form created from scratch" do
    it "persists the default groups the editor shows", :aggregate_failures do
      shown = form.attribute_groups.map { it.key.to_s }

      reconcile

      expect(form.form_groups.reload.map(&:default_key)).to eq(shown)
      expect(form.reload.attribute_groups.map { it.key.to_s }).to eq(shown)
      expect(form.attribute_groups.map(&:record_id)).to all(be_present)
    end

    it "gives every offered attribute a membership" do
      reconcile

      expect(form.form_attributes.reload.map(&:key)).to match_array(form.work_package_attributes.keys)
    end

    it "changes nothing when run again" do
      described_class.new(form).call

      expect { described_class.new(form).call }
        .not_to change { [form.form_groups.reload.pluck(:id, :position), form.form_attributes.reload.pluck(:id, :position)] }
    end
  end

  context "with a form used by variants" do
    def stored_keys(form) = form.form_groups.reload.map(&:default_key)

    context "when the type is a milestone" do
      let(:variant) { create(:type_milestone).default_variant }
      let(:form) { variant.form_configuration }

      it "keeps the variant's effective groups", :aggregate_failures do
        before = variant.attribute_groups.map(&:key)

        reconcile

        expect(variant.reload.attribute_groups.map(&:key)).to eq(before)
        expect(stored_keys(form)).not_to include("estimates_and_progress")
      end
    end

    context "when the type is not a milestone" do
      let(:variant) { create(:type).default_variant }
      let(:form) { variant.form_configuration }

      it "keeps the variant's effective groups", :aggregate_failures do
        before = variant.attribute_groups.map(&:key)

        reconcile

        expect(variant.reload.attribute_groups.map(&:key)).to eq(before)
        expect(stored_keys(form)).to eq(before.map(&:to_s))
      end
    end

    context "when a milestone and a non-milestone variant disagree on the defaults" do
      let(:form) { create(:type).default_variant.form_configuration }

      before do
        milestone = create(:type_milestone).default_variant
        orphan = milestone.form_configuration
        milestone.update!(form_configuration: form)
        orphan.reload.destroy!
      end

      it "stores the neutral defaults" do
        reconcile

        expect(stored_keys(form)).to include("estimates_and_progress")
      end
    end
  end

  context "with a form whose groups were all removed" do
    before { create(:form_configuration_attribute, form_configuration: form, attribute_key: "priority") }

    it "leaves it empty" do
      reconcile

      expect(form.form_groups.reload).to be_empty
    end
  end

  context "with an attribute that appeared after the last save" do
    let!(:group) { create(:form_configuration_group, form_configuration: form, label: "Details") }
    let!(:custom_field) { create(:wp_custom_field) }

    it "adds an inactive membership for it and keeps the groups", :aggregate_failures do
      reconcile

      membership = form.form_attributes.find_by(custom_field_id: custom_field.id)
      expect(membership).to be_present
      expect(membership).not_to be_active
      expect(form.form_groups.reload).to contain_exactly(group)
    end
  end
end
