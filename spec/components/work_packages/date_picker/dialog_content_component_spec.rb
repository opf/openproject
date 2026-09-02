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

RSpec.describe WorkPackages::DatePicker::DialogContentComponent, type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  create_shared_association_defaults_for_work_package_factory

  subject(:dialog_content) do
    with_controller_class(WorkPackages::DatePickerController) do
      with_request_url("/work_packages/:work_package_id/date_picker") do
        render_inline(described_class.new(work_package:, schedule_manually:))
      end
    end
  end

  context "when the work package is new" do
    let(:work_package) { build(:work_package) }

    context "when manually scheduled" do
      let(:schedule_manually) { true }

      it "shows the date form" do
        expect(dialog_content).to have_field(I18n.t("attributes.start_date"))
        expect(dialog_content).to have_field(I18n.t("attributes.due_date"))
        expect(dialog_content).to have_field(WorkPackage.human_attribute_name("duration"))
      end

      it "has an enabled save button" do
        expect(dialog_content).to have_button(I18n.t("button_save"), disabled: false)
      end

      it "can switch to automatic scheduling mode" do
        expect(dialog_content).to have_link(I18n.t("work_packages.datepicker_modal.mode.automatic"))
      end
    end

    context "when automatically scheduled" do
      let(:schedule_manually) { false }

      it "does not show the date form" do
        expect(dialog_content).to have_no_field(I18n.t("attributes.start_date"), disabled: :all)
        expect(dialog_content).to have_no_field(I18n.t("attributes.due_date"), disabled: :all)
      end

      it "displays a blank slate explaining it can't be automatically scheduled because there are no predecessors" do
        expect(dialog_content).to have_text(I18n.t("work_packages.datepicker_modal.blankslate.title"))
        expect(dialog_content).to have_text(I18n.t("work_packages.datepicker_modal.blankslate.description"))
      end

      it "has a disabled save button" do
        expect(dialog_content).to have_button(I18n.t("button_save"), disabled: true)
      end
    end
  end

  context "when manually scheduled" do
    let(:schedule_manually) { true }
    let(:work_package) { build_stubbed(:work_package) }

    it "shows the date form" do
      expect(dialog_content).to have_field(I18n.t("attributes.start_date"))
      expect(dialog_content).to have_field(I18n.t("attributes.due_date"))
    end

    it "has an enabled save button" do
      expect(dialog_content).to have_button(I18n.t("button_save"), disabled: false)
    end

    it "can switch to automatic scheduling mode" do
      expect(dialog_content).to have_link(I18n.t("work_packages.datepicker_modal.mode.automatic"))
    end

    it "does not show a relation banner without predecessors, successors, a parent, or children" do
      expect(dialog_content).to have_no_css("[data-test-selector='op-modal-banner-warning']")
      expect(dialog_content).to have_no_css("[data-test-selector='op-modal-banner-info']")
    end

    context "with a child" do
      let(:work_package) { build_stubbed(:work_package, children: [build_stubbed(:work_package)]) }

      it "shows that child dates are ignored" do
        expect(dialog_content).to have_css(
          "[data-test-selector='op-modal-banner-warning']",
          text: "Manually scheduled. Dates not affected by relations. " \
                "This has child work packages but their start dates are ignored.",
          normalize_ws: true
        )
      end
    end

    context "with a direct predecessor" do
      shared_let_work_packages(<<~TABLE)
        subject      | MTWTFSS | scheduling mode | predecessors
        predecessor  |         | manual          |
        work_package |         | automatic       | predecessor
      TABLE

      it "shows that predecessor dates are ignored" do
        expect(dialog_content).to have_css(
          "[data-test-selector='op-modal-banner-warning']",
          text: "Manually scheduled. Dates not affected by relations. " \
                'Click on "Show relations" for Gantt overview.',
          normalize_ws: true
        )
      end
    end
  end

  context "when automatically scheduled" do
    let(:schedule_manually) { false }

    context "without any predecessors nor children" do
      let(:work_package) { build_stubbed(:work_package) }

      it "does not show the date form" do
        expect(dialog_content).to have_no_field(I18n.t("attributes.start_date"), disabled: :all)
        expect(dialog_content).to have_no_field(I18n.t("attributes.due_date"), disabled: :all)
      end

      it "displays a blank slate explaining it can't be automatically scheduled because there are no predecessors" do
        expect(dialog_content).to have_text(I18n.t("work_packages.datepicker_modal.blankslate.title"))
        expect(dialog_content).to have_text(I18n.t("work_packages.datepicker_modal.blankslate.description"))
      end

      it "has a disabled save button" do
        expect(dialog_content).to have_button(I18n.t("button_save"), disabled: true)
      end

      it "does not show a relation banner" do
        expect(dialog_content).to have_no_css("[data-test-selector='op-modal-banner-warning']")
        expect(dialog_content).to have_no_css("[data-test-selector='op-modal-banner-info']")
      end
    end

    context "with a child" do
      let(:work_package) { build_stubbed(:work_package, children: [build_stubbed(:work_package)]) }

      it "shows the date form with disabled fields" do
        expect(dialog_content).to have_field(I18n.t("attributes.start_date"), disabled: true)
        expect(dialog_content).to have_field(I18n.t("attributes.due_date"), disabled: true)
      end

      it "shows the banner 'The dates are determined by child work packages'" do
        expect(dialog_content).to have_text(I18n.t("work_packages.datepicker_modal.banner.title.automatic_with_children"))
      end

      it "has an enabled save button" do
        expect(dialog_content).to have_button(I18n.t("button_save"), disabled: false)
      end
    end

    context "with a direct predecessor" do
      shared_let_work_packages(<<~TABLE)
        subject      | MTWTFSS | scheduling mode | predecessors
        predecessor  |         | manual          |
        work_package |         | automatic       | predecessor
      TABLE

      it "shows the date form with disabled fields" do
        expect(dialog_content).to have_field(I18n.t("attributes.start_date"), disabled: true)
        expect(dialog_content).to have_field(I18n.t("attributes.due_date"), disabled: false)
      end

      it "shows the banner 'The start date is set by a predecessor'" do
        expect(dialog_content).to have_text(I18n.t("work_packages.datepicker_modal.banner.title.automatic_with_predecessor"))
      end

      it "has an enabled save button" do
        expect(dialog_content).to have_button(I18n.t("button_save"), disabled: false)
      end
    end

    context "with an indirect predecessor involved in scheduling (like an automatically scheduled parent having a predecessor)" do
      shared_let_work_packages(<<~TABLE)
        hierarchy          | MTWTFSS | scheduling mode | predecessors
        parent_predecessor |         | manual          |
        parent             |         | automatic       | parent_predecessor
          work_package     |         | automatic       |
      TABLE

      it "shows the date form with disabled fields" do
        expect(dialog_content).to have_field(I18n.t("attributes.start_date"), disabled: true)
        expect(dialog_content).to have_field(I18n.t("attributes.due_date"), disabled: false)
      end

      it "shows the banner 'The start date is set by a predecessor'" do
        expect(dialog_content).to have_text(I18n.t("work_packages.datepicker_modal.banner.title.automatic_with_predecessor"))
      end

      it "has an enabled save button" do
        expect(dialog_content).to have_button(I18n.t("button_save"), disabled: false)
      end
    end

    context "with an indirect predecessor not involved in scheduling (like a manually scheduled parent having a predecessor)" do
      shared_let_work_packages(<<~TABLE)
        hierarchy          | MTWTFSS | scheduling mode | predecessors
        parent_predecessor |         | manual          |
        parent             |         | manual          | parent_predecessor
          work_package     |         | automatic       |
      TABLE

      it "does not show the date form" do
        expect(dialog_content).to have_no_field(I18n.t("attributes.start_date"), disabled: :all)
        expect(dialog_content).to have_no_field(I18n.t("attributes.due_date"), disabled: :all)
      end

      it "displays a blank slate explaining it can't be automatically scheduled because there are no predecessors" do
        expect(dialog_content).to have_text(I18n.t("work_packages.datepicker_modal.blankslate.title"))
        expect(dialog_content).to have_text(I18n.t("work_packages.datepicker_modal.blankslate.description"))
      end

      it "has a disabled save button" do
        expect(dialog_content).to have_button(I18n.t("button_save"), disabled: true)
      end
    end
  end

  context "with a direct successor but no predecessor, parent, or children" do
    shared_let(:work_package) { create(:work_package) }
    shared_let(:successor) { create(:work_package) }
    let!(:relation) do
      create(:relation,
             from: work_package,
             to: successor,
             relation_type: Relation::TYPE_PRECEDES)
    end

    context "when manually scheduled" do
      let(:schedule_manually) { true }

      it "shows that successor dates are ignored" do
        expect(dialog_content).to have_css(
          "[data-test-selector='op-modal-banner-warning']",
          text: "Manually scheduled. Dates not affected by relations. " \
                'Click on "Show relations" for Gantt overview.',
          normalize_ws: true
        )
      end
    end

    context "when automatically scheduled" do
      let(:schedule_manually) { false }

      it "does not show a relation banner" do
        expect(dialog_content).to have_no_css("[data-test-selector='op-modal-banner-warning']")
        expect(dialog_content).to have_no_css("[data-test-selector='op-modal-banner-info']")
      end
    end
  end
end
