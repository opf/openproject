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

require "rails_helper"

RSpec.describe ResourcePlannerViews::UserCardList::CardComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:current_user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end
  shared_let(:card_user) do
    create(:user, firstname: "Carl", lastname: "Cardman",
                  member_with_permissions: { project => %i[view_resource_planners] })
  end

  let(:details_path) { "/projects/x/users/#{card_user.id}/resource_allocations" }
  let(:remove_path) { nil }
  let(:utilization) { nil }
  let(:card_fields) { [] }
  let(:working_schedules) { [] }

  subject(:rendered) do
    render_inline(described_class.new(user: card_user, details_path:, card_fields:, remove_path:, utilization:,
                                      working_schedules:))
    page
  end

  before { login_as(current_user) }

  it "wires the whole card to open the details path" do
    expect(rendered).to have_css(
      "[data-test-selector='op-user-card']" \
      "[data-resource-management--user-card-url-value='#{details_path}']"
    )
  end

  context "for a user the current user cannot see" do
    let(:hidden_user) { create(:user, firstname: "Hidden", lastname: "User") }

    it "renders nothing" do
      render_inline(described_class.new(user: hidden_user, details_path: "/x"))

      expect(page).to have_no_text("Hidden User")
    end
  end

  describe "the status badge" do
    it "renders an active user's status as a success label" do
      expect(rendered).to have_css("span.Label--success", text: I18n.t(:status_active))
    end

    context "for an inactive user" do
      before { card_user.update_column(:status, Principal.statuses[:locked]) }

      it "renders the status as an attention label" do
        expect(rendered).to have_css("span.Label--attention", text: I18n.t("user.locked"))
        expect(rendered).to have_no_css("span.Label--success")
      end
    end
  end

  describe "the user attribute rows" do
    let(:section) { create(:user_custom_field_section) }

    context "with a multi value field exceeding the 3 value limit" do
      let!(:skills) do
        create(:user_custom_field, :multi_list, name: "Skills",
                                                user_custom_field_section: section, visible_on_user_card: true,
                                                possible_values: %w[React Rails Node HTML CSS])
      end
      let(:card_user) do
        create(:user, firstname: "Carl", lastname: "Cardman",
                      member_with_permissions: { project => %i[view_resource_planners] },
                      custom_values: skills.possible_values.map do |opt|
                        build(:custom_value, custom_field: skills, value: opt)
                      end)
      end
      let(:card_fields) { [skills.column_name] }

      it "renders the first 3 values and an overflow counter for the rest" do
        expect(rendered).to have_text("Skills")
        expect(rendered).to have_css("span.Label", text: "React")
        expect(rendered).to have_css("span.Label", text: "Rails")
        expect(rendered).to have_css("span.Label", text: "Node")
        expect(rendered).to have_no_css("span.Label", text: "HTML")
        expect(rendered).to have_no_css("span.Label", text: "CSS")
        expect(rendered).to have_text(I18n.t("resource_management.user_card_list.card.multi_value_more", count: 2))
      end
    end

    context "with a single value field" do
      let!(:location) do
        create(:user_custom_field, :string, name: "Location",
                                            user_custom_field_section: section, visible_on_user_card: true)
      end
      let(:card_user) do
        create(:user, firstname: "Carl", lastname: "Cardman",
                      member_with_permissions: { project => %i[view_resource_planners] },
                      custom_values: [build(:custom_value, custom_field: location, value: "Berlin")])
      end
      let(:card_fields) { [location.column_name] }

      it "renders the value" do
        expect(rendered).to have_text("Location")
        expect(rendered).to have_text("Berlin")
      end
    end
  end

  describe "the working hours row" do
    let(:card_fields) { %w[working_times] }

    context "with a uniform schedule" do
      let(:working_schedules) do
        [build(:user_working_hours, user: card_user, valid_from: 1.year.ago.to_date,
                                    monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
                                    saturday: 0, sunday: 0)]
      end

      it "renders the per day breakdown" do
        expect(rendered).to have_text("Mon-Fri 8h")
      end
    end

    context "with a non uniform schedule" do
      let(:working_schedules) do
        [build(:user_working_hours, user: card_user, valid_from: 1.year.ago.to_date,
                                    monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 360,
                                    saturday: 0, sunday: 0)]
      end

      it "renders the per day breakdown" do
        expect(rendered).to have_text("Mon-Thu 8h, Fri 6h")
      end
    end

    context "with a reduced availability factor" do
      let(:working_schedules) do
        [build(:user_working_hours, user: card_user, valid_from: 1.year.ago.to_date, availability_factor: 80,
                                    monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
                                    saturday: 0, sunday: 0)]
      end

      it "appends the compact availability note" do
        expect(rendered).to have_text("Mon-Fri 8h (80% available)")
      end
    end

    context "without a configured schedule" do
      it "renders the placeholder" do
        expect(rendered).to have_text(I18n.t("resource_management.user_card_list.working_hours.blank"))
      end
    end

    context "with a schedule that changes" do
      let(:working_schedules) do
        [build(:user_working_hours, user: card_user, valid_from: Date.new(2025, 1, 1),
                                    monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
                                    saturday: 0, sunday: 0),
         build(:user_working_hours, user: card_user, valid_from: Date.new(2025, 9, 1),
                                    monday: 240, tuesday: 240, wednesday: 240, thursday: 240, friday: 240,
                                    saturday: 0, sunday: 0)]
      end

      it "renders all relevant schedules with their end dates" do
        expect(rendered).to have_text(
          "Mon-Fri 8h until #{I18n.l(Date.new(2025, 8, 31))}, Mon-Fri 4h"
        )
      end
    end
  end

  describe "the utilization section" do
    context "with a utilization value" do
      let(:utilization) { 75 }

      it "renders the utilization label and percentage" do
        expect(rendered).to have_text(I18n.t("resource_management.user_card_list.utilization.label"))
        expect(rendered).to have_text("75%")
      end
    end

    context "without a utilization value" do
      it "omits the utilization section" do
        expect(rendered).to have_no_text(I18n.t("resource_management.user_card_list.utilization.label"))
      end
    end
  end

  describe "the remove button" do
    context "in manual mode" do
      let(:remove_path) { "/projects/x/views/1/users/#{card_user.id}" }

      it "renders a delete action" do
        expect(rendered).to have_css("a[href='#{remove_path}'][data-turbo-method='delete']")
      end
    end

    context "in automatic mode" do
      it "renders no delete action" do
        expect(rendered).to have_no_css("a[data-turbo-method='delete']")
      end
    end
  end

  describe "the department row" do
    let(:card_fields) { %w[department] }

    context "when the user belongs to a department" do
      before { create(:department, lastname: "Engineering", members: [card_user]) }

      it "renders the department name" do
        expect(rendered).to have_text("Engineering")
      end
    end

    context "when the user has no department" do
      it "renders no attribute row" do
        expect(rendered).to have_no_css(".op-user-card--attribute-value")
      end
    end
  end

  describe "the job title subtitle" do
    let!(:job_title) do
      create(:user_custom_field, :string, name: "Position", semantic_key: :job_title)
    end
    let(:card_user) do
      create(:user, firstname: "Carl", lastname: "Cardman",
                    member_with_permissions: { project => %i[view_resource_planners] },
                    custom_values: [build(:custom_value, custom_field: job_title, value: "Lead Engineer")])
    end

    it "renders the job title" do
      expect(rendered).to have_text("Lead Engineer")
    end
  end
end
