# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "rails_helper"

RSpec.describe WorkPackageTypes::SubjectConfigurationComponent, type: :component do
  let(:type) { create(:type) }
  let(:subject_configuration_form_data) { nil }

  subject(:render_component) do
    render_inline(described_class.new(type, subject_configuration_form_data:))
  end

  context "when enterprise edition is activated", with_ee: %i[work_package_subject_generation] do
    it "shows no enterprise banner" do
      render_component

      expect(page).not_to have_enterprise_banner
    end

    it "enables mode selectors", :aggregate_failures do
      render_component

      expect(page.find("input[type=radio][value=generated]")).not_to be_disabled
      expect(page.find("input[type=radio][value=manual]")).not_to be_disabled
    end

    context "if component is rendered without form values in parameters" do
      before do
        render_component
      end

      context "if work package type has no subject pattern configured" do
        it "must have manual option checked" do
          expect(page.find("input[type=radio][value=manual]")).to be_checked
        end
      end

      context "if work package type has subject pattern configured" do
        let(:type) { create(:type, patterns: { subject: { blueprint: "Created by {{assignee}}", enabled: true } }) }

        it "must have generated option checked and pattern input filled" do
          expect(page.find("input[type=radio][value=generated]")).to be_checked
          expect(page.find(hidden_input_field_selector, visible: false).value).to eq("Created by {{assignee}}")
        end
      end
    end

    context "if component is rendered with form values in parameters" do
      before do
        render_component
      end

      context "if work package type has subject pattern configured, but form params have option manual selected" do
        let(:type) { create(:type, patterns: { subject: { blueprint: "Created by {{assignee}}", enabled: true } }) }
        let(:subject_configuration_form_data) { { subject_configuration: :manual } }

        it "must have manual option checked" do
          expect(page.find("input[type=radio][value=manual]")).to be_checked
        end
      end

      context "if work package type has no subject pattern configured, but form params have a pattern" do
        let(:subject_configuration_form_data) do
          {
            subject_configuration: :generated,
            pattern: "Created by {{assignee}}"
          }
        end

        it "must have generated option checked and pattern input filled" do
          expect(page.find("input[type=radio][value=generated]")).to be_checked
          expect(page.find(hidden_input_field_selector, visible: false).value).to eq("Created by {{assignee}}")
        end
      end
    end
  end

  context "when enterprise edition is not activated", with_ee: %i[] do
    it "shows the large enterprise banner" do
      render_component

      expect(page).to have_enterprise_banner(:professional, class: "op-enterprise-banner_large")
    end

    context "and when the subject is already automatically generated" do
      let(:type) { create(:type, patterns: { subject: { blueprint: "Hello world", enabled: true } }) }

      it "shows the inline enterprise banner" do
        render_component

        expect(page).to have_enterprise_banner(:professional, class: "op-enterprise-banner_medium")
      end

      it "enables mode selectors", :aggregate_failures do
        render_component

        expect(page.find("input[type=radio][value=generated]")).to be_disabled
        expect(page.find("input[type=radio][value=manual]")).not_to be_disabled
      end
    end
  end

  private

  def hidden_input_field_selector
    "input[type=hidden][id=work_package_types_forms_subject_configuration_form_model_pattern]"
  end
end
