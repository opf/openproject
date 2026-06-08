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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe OpenProject::Common::BorderBoxListComponent, type: :component do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, subject: "Default WP", project:) }
  shared_let(:override_work_package) { create(:work_package, subject: "Override WP", project:) }

  current_user { user }

  let(:default_wp_item_class) do
    stub_const(
      "TestDefaultWorkPackageItem",
      Class.new(ApplicationComponent) do
        include ActionView::RecordIdentifier

        delegate :with_metric, :with_menu, to: :card

        def initialize(work_package:, project:, container:, params: {}, current_user: User.current, **system_arguments) # rubocop:disable Lint/UnusedMethodArgument
          super()

          @work_package = work_package
          @project = project
          @container = container
          @current_user = current_user
          @system_arguments = system_arguments
        end

        def row_args
          @system_arguments.merge(
            id: "default_wp_#{@work_package.id}",
            data: @system_arguments.fetch(:data, {}).merge(
              container: Array(@container).map { |c| c.respond_to?(:id) ? c.id : c }.join("_"),
              project: @project&.id,
              current_user: @current_user&.id
            )
          )
        end

        def card
          @card ||= TestWorkPackageCard.new(prefix: "default", subject: @work_package.subject)
        end

        def before_render
          content
        end

        def call
          render(card)
        end
      end
    )
  end

  let(:override_wp_item_class) do
    stub_const(
      "TestOverrideWorkPackageItem",
      Class.new(default_wp_item_class) do
        def row_args
          super.merge(id: "override_wp_#{@work_package.id}")
        end

        def card
          @card ||= TestWorkPackageCard.new(prefix: "override", subject: @work_package.subject)
        end
      end
    )
  end

  before do
    stub_const(
      "TestWorkPackageCard",
      Class.new(ApplicationComponent) do
        renders_one :metric
        renders_one :menu

        def initialize(prefix:, subject:)
          super()

          @prefix = prefix
          @subject = subject
        end

        def call
          safe_join([tag.span("#{@prefix} #{@subject}"), metric, menu].compact)
        end
      end
    )
  end

  describe "full rendering" do
    subject(:rendered_component) do
      render_inline(
        described_class.new(container: "test-list", current_user: user)
      ) do |list|
        list.with_header(title: "Header title", count: 3)
        list.with_item(id: "manual-item") { "Manual item" }
        list.with_work_package_item(
          work_package:,
          component_klass: default_wp_item_class,
          data: { source: "slot" }
        ) do |item|
          item.card.with_metric { "Metric content" }
        end
        list.with_work_package_item(
          work_package: override_work_package,
          component_klass: override_wp_item_class
        ) do |item|
          item.with_menu { "Menu content" }
        end
        list.with_footer { "Footer content" }
      end
    end

    it_behaves_like "rendering Box", row_count: 3, header: true, footer: true

    it "renders the header with title" do
      expect(rendered_component).to have_heading("Header title", level: 4)
    end

    it "renders the header count badge" do
      expect(rendered_component).to have_css(".Counter", text: "3")
    end

    it "renders generic items as content rows" do
      expect(rendered_component).to have_css(".Box-row#manual-item", text: "Manual item")
    end

    it "renders the footer" do
      expect(rendered_component).to have_css(".Box-footer", text: "Footer content")
    end

    it "renders the default work-package item" do
      expect(rendered_component).to have_css(
        ".Box-row#default_wp_#{work_package.id}",
        text: "default Default WP"
      )
    end

    it "renders the overridden work-package item" do
      expect(rendered_component).to have_css(
        ".Box-row#override_wp_#{override_work_package.id}",
        text: "override Override WP"
      )
    end

    it "captures work-package item customization blocks" do
      expect(rendered_component).to have_text("Metric content")
    end

    it "delegates menu customization to the card" do
      expect(rendered_component).to have_text("Menu content")
    end
  end

  describe "header" do
    it "renders a description below the title" do
      rendered = render_inline(
        described_class.new(container: "hdr-test")
      ) do |list|
        list.with_header(title: "My title") do |header|
          header.with_description { "Some description" }
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_heading("My title", level: 4)
      expect(rendered).to have_css(".op-border-box-list-header--description", text: "Some description")
    end

    it "forwards system arguments to the description text" do
      rendered = render_inline(
        described_class.new(container: "hdr-description-args")
      ) do |list|
        list.with_header(title: "My title") do |header|
          header.with_description(display: :flex, direction: :column, classes: "row-gap-2") do
            "Some description"
          end
        end
        list.with_item { "row" }
      end

      expect(rendered)
        .to have_css(".op-border-box-list-header--description .d-flex.flex-column.row-gap-2.color-fg-muted",
                     text: "Some description")
    end

    it "renders multiple action buttons" do
      rendered = render_inline(
        described_class.new(container: "hdr-actions")
      ) do |list|
        list.with_header(title: "Actions") do |header|
          header.with_action_button(scheme: :primary) { "Add" }
          header.with_action_button(scheme: :default) { "Edit" }
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_button("Add")
      expect(rendered).to have_button("Edit")
    end

    it "renders a menu in the header" do
      rendered = render_inline(
        described_class.new(container: "hdr-menu")
      ) do |list|
        list.with_header(title: "With menu") do |header|
          header.with_menu do |menu|
            menu.with_item(label: "Option A", value: "a")
          end
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Box-header")
      expect(rendered).to have_css("action-menu")
      expect(rendered).to have_css("tool-tip[data-type='label']", text: I18n.t(:label_actions))
    end

    it "infers the count from rendered items" do
      rendered = render_inline(
        described_class.new(container: "hdr-inferred-count")
      ) do |list|
        list.with_header(title: "Counted", count: true)
        list.with_item { "first row" }
        list.with_item { "second row" }
      end

      expect(rendered).to have_css(".Counter", text: "2")
    end

    it "does not render a count when count is false" do
      rendered = render_inline(
        described_class.new(container: "hdr-false-count")
      ) do |list|
        list.with_header(title: "Uncounted", count: false)
        list.with_item { "row" }
      end

      expect(rendered).to have_no_css(".Counter")
    end

    it "does not render a count when count is nil" do
      rendered = render_inline(
        described_class.new(container: "hdr-nil-count")
      ) do |list|
        list.with_header(title: "Uncounted", count: nil)
        list.with_item { "row" }
      end

      expect(rendered).to have_no_css(".Counter")
    end

    it "renders an explicit count" do
      rendered = render_inline(
        described_class.new(container: "hdr-explicit-count")
      ) do |list|
        list.with_header(title: "Counted", count: 5)
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Counter", text: "5")
    end

    it "keeps zero counts hidden by default" do
      rendered = render_inline(
        described_class.new(container: "hdr-zero-count")
      ) do |list|
        list.with_header(title: "Counted", count: 0)
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Counter[hidden]", text: "0", visible: :all)
    end

    it "allows zero counts to be shown through count arguments" do
      rendered = render_inline(
        described_class.new(container: "hdr-visible-zero-count")
      ) do |list|
        list.with_header(title: "Counted", count: 0, count_arguments: { hide_if_zero: false })
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Counter:not([hidden])", text: "0")
    end

    it "sets a default aria-label on the counter" do
      rendered = render_inline(
        described_class.new(container: "hdr-default-aria")
      ) do |list|
        list.with_header(title: "Counted", count: 5)
        list.with_item { "row" }
      end

      expect(rendered).to have_css(
        ".Counter",
        text: "5",
        aria: { label: I18n.t(:label_x_items, count: 5), live: nil }
      )
    end

    it "adds aria-live to the counter when the list is interactive" do
      rendered = render_inline(
        described_class.new(container: "hdr-interactive-aria", interactive: true)
      ) do |list|
        list.with_header(title: "Counted", count: 5)
        list.with_item { "row" }
      end

      expect(rendered).to have_css(
        ".Counter",
        text: "5",
        aria: { label: I18n.t(:label_x_items, count: 5), live: "polite" }
      )
    end

    it "preserves caller-provided counter aria attributes" do
      rendered = render_inline(
        described_class.new(container: "hdr-custom-counter-aria", interactive: true)
      ) do |list|
        list.with_header(
          title: "Counted",
          count: 5,
          count_arguments: { aria: { describedby: "counter-help", live: "assertive" } }
        )
        list.with_item { "row" }
      end

      expect(rendered).to have_css(
        ".Counter",
        text: "5",
        aria: {
          label: I18n.t(:label_x_items, count: 5),
          describedby: "counter-help",
          live: "assertive"
        }
      )
    end

    it "uses the default aria-label when count is inferred" do
      rendered = render_inline(
        described_class.new(container: "hdr-inferred-aria")
      ) do |list|
        list.with_header(title: "Counted", count: true)
        list.with_item { "one" }
        list.with_item { "two" }
      end

      expect(rendered).to have_css(
        ".Counter",
        text: "2",
        aria: { label: I18n.t(:label_x_items, count: 2) }
      )
    end

    it "allows count_label to override the default aria-label" do
      rendered = render_inline(
        described_class.new(container: "hdr-custom-label")
      ) do |list|
        list.with_header(title: "Counted", count: 3, count_label: "3 work packages")
        list.with_item { "row" }
      end

      expect(rendered).to have_css(
        ".Counter",
        text: "3",
        aria: { label: "3 work packages" }
      )
    end

    it "allows the title tag to be customized" do
      rendered = render_inline(
        described_class.new(container: "hdr-title-tag")
      ) do |list|
        list.with_header(title: "Custom title", title_tag: :h3)
        list.with_item { "row" }
      end

      expect(rendered).to have_heading("Custom title", level: 3)
    end

    it "forwards title arguments" do
      rendered = render_inline(
        described_class.new(container: "hdr-title-args")
      ) do |list|
        list.with_header(
          title: "Described title",
          title_tag: :h4,
          title_arguments: {
            tag: :h2,
            id: "custom-title",
            classes: "custom-title-class",
            data: { title: "custom" },
            aria: { describedby: "goal-text" }
          }
        )
        list.with_item { "row" }
      end

      expect(rendered).to have_css(
        "h4#custom-title.Box-title.custom-title-class[data-title='custom']",
        text: "Described title",
        aria: { describedby: "goal-text" }
      )
    end
  end

  describe "header collapsible behavior" do
    it "sets collapsible_id from list and footer ids" do
      rendered = render_inline(
        described_class.new(container: "collapse-test", collapsible: true)
      ) do |list|
        list.with_header(title: "Collapsible")
        list.with_item { "row" }
        list.with_footer { "foot" }
      end

      list_id = "collapse-test_list"
      footer_id = "collapse-test_footer"

      expect(rendered).to have_css(
        "[aria-controls='#{list_id} #{footer_id}']"
      )
    end

    it "sets collapsible_id from list id only when no footer" do
      rendered = render_inline(
        described_class.new(container: "collapse-no-footer", collapsible: true)
      ) do |list|
        list.with_header(title: "No footer")
        list.with_item { "row" }
      end

      expect(rendered).to have_css(
        "[aria-controls='collapse-no-footer_list']"
      )
    end

    it "forwards title arguments to the collapsible title" do
      rendered = render_inline(
        described_class.new(container: "collapse-title-args", collapsible: true)
      ) do |list|
        list.with_header(
          title: "Collapsible",
          title_arguments: { aria: { describedby: "collapsible-help" } }
        )
        list.with_item(id: "collapsible-help") { "Helpful row" }
      end

      expect(rendered).to have_heading(
        "Collapsible",
        level: 4,
        accessible_description: "Helpful row"
      )
      expect(rendered).to have_css("h4", text: "Collapsible", aria: { describedby: "collapsible-help" })
    end
  end

  describe "generic items" do
    subject(:rendered_component) do
      render_inline(
        described_class.new(container: "generic-items")
      ) do |list|
        list.with_item(id: "row-1") { "First" }
        list.with_item(id: "row-2") { "Second" }
      end
    end

    it "renders content block rows" do
      expect(rendered_component).to have_css(".Box-row#row-1", text: "First")
      expect(rendered_component).to have_css(".Box-row#row-2", text: "Second")
    end

    it "renders the expected number of rows" do
      expect(rendered_component).to have_css(".Box-row", count: 2)
    end
  end

  describe "work-package items" do
    describe "with the default WorkPackageItem" do
      subject(:rendered_component) do
        render_inline(
          described_class.new(container: "wp-default", current_user: user)
        ) do |list|
          list.with_work_package_item(work_package:)
        end
      end

      it "renders the work package row" do
        expect(rendered_component).to have_css(
          ".Box-row#work_package_#{work_package.id}"
        )
      end

      it "applies clickable row classes" do
        expect(rendered_component).to have_css(
          ".Box-row.Box-row--clickable"
        )
      end

      it "applies the Box-card class to the work-package card" do
        expect(rendered_component).to have_css(".op-work-package-card.Box-card")
      end

      it "sets the test selector" do
        item = described_class::WorkPackageItem.new(
          work_package:,
          project:,
          container: "wp-default",
          current_user: user
        )

        expect(item.row_args[:test_selector]).to eq("work-package-#{work_package.id}")
        expect(rendered_component).to have_css(
          ".Box-row[data-test-selector='work-package-#{work_package.id}']"
        )
      end

      it "delegates metric customization to the work-package card" do
        rendered = render_inline(
          described_class.new(container: "wp-default-metric", current_user: user)
        ) do |list|
          list.with_work_package_item(work_package:) do |item|
            item.with_metric { "Custom metric" }
          end
        end

        expect(rendered).to have_text("Custom metric")
      end
    end

    describe "with an overridden component_klass" do
      subject(:rendered_component) do
        render_inline(
          described_class.new(container: "wp-override", current_user: user)
        ) do |list|
          list.with_work_package_item(
            work_package: override_work_package,
            component_klass: override_wp_item_class
          )
        end
      end

      it "uses the provided component class" do
        expect(rendered_component).to have_css(
          ".Box-row#override_wp_#{override_work_package.id}",
          text: "override Override WP"
        )
      end
    end

    describe "injected container: and current_user:" do
      subject(:rendered_component) do
        render_inline(
          described_class.new(container: "injection-test", current_user: user)
        ) do |list|
          list.with_work_package_item(
            work_package:,
            component_klass: default_wp_item_class
          )
        end
      end

      it "injects the list container into the item" do
        expect(rendered_component).to have_css(
          ".Box-row[data-container='injection-test']"
        )
      end

      it "injects the list current_user into the item" do
        expect(rendered_component).to have_css(
          ".Box-row[data-current-user='#{user.id}']"
        )
      end
    end

    describe "project defaults to work_package.project" do
      subject(:rendered_component) do
        render_inline(
          described_class.new(container: "project-default", current_user: user)
        ) do |list|
          list.with_work_package_item(
            work_package:,
            component_klass: default_wp_item_class
          )
        end
      end

      it "passes the work package's project when project: is omitted" do
        expect(rendered_component).to have_css(
          ".Box-row[data-project='#{work_package.project.id}']"
        )
      end
    end
  end

  describe "empty state" do
    it "renders a Blankslate when no items are present" do
      rendered = render_inline(
        described_class.new(container: "empty-list")
      ) do |list|
        list.with_empty_state(title: "Nothing here", description: "Add some items", icon: :inbox)
      end

      expect(rendered).to have_css(".blankslate")
      expect(rendered).to have_text("Nothing here")
      expect(rendered).to have_text("Add some items")
    end

    it "does not render the empty state when items are present" do
      rendered = render_inline(
        described_class.new(container: "non-empty-list")
      ) do |list|
        list.with_empty_state(title: "Nothing here")
        list.with_item { "Has content" }
      end

      expect(rendered).to have_no_css(".blankslate")
      expect(rendered).to have_text("Has content")
    end

    it "does not set aria role and live attributes on the empty state by default" do
      rendered = render_inline(
        described_class.new(container: "empty-aria")
      ) do |list|
        list.with_empty_state(title: "Empty")
      end

      expect(rendered).to have_no_role(:status)
      expect(rendered).to have_css(".blankslate", aria: { live: nil })
    end

    it "sets aria role and live attributes on the empty state when the list is interactive" do
      rendered = render_inline(
        described_class.new(container: "empty-interactive-aria", interactive: true)
      ) do |list|
        list.with_empty_state(title: "Empty")
      end

      expect(rendered).to have_role(:status, aria: { live: "polite" })
    end

    it "preserves caller-provided empty state aria attributes" do
      rendered = render_inline(
        described_class.new(container: "empty-custom-aria", interactive: true)
      ) do |list|
        list.with_empty_state(
          title: "Empty",
          role: "alert",
          aria: { live: "assertive", describedby: "empty-help" }
        )
      end

      expect(rendered).to have_alert(aria: { live: "assertive", describedby: "empty-help" })
    end
  end

  describe "footer rendering" do
    subject(:rendered_component) do
      render_inline(
        described_class.new(container: "footer-test")
      ) do |list|
        list.with_item { "row" }
        list.with_footer(classes: "custom-footer") { "Custom footer" }
      end
    end

    it "renders as a proper BorderBox footer" do
      expect(rendered_component).to have_css(".Box-footer", text: "Custom footer")
    end

    it "auto-derives the footer id from the box id" do
      expect(rendered_component).to have_css(".Box-footer#footer-test_footer")
    end
  end

  describe "container-derived DOM IDs" do
    context "with a string container" do
      subject(:rendered_component) do
        render_inline(
          described_class.new(container: "my-widget")
        ) do |list|
          list.with_item { "row" }
        end
      end

      it "derives the box id from container" do
        expect(rendered_component).to have_css(".Box#my-widget")
      end

      it "derives the list id from container" do
        expect(rendered_component).to have_css("ul#my-widget_list")
      end
    end

    it "derives the header id from the box id" do
      rendered = render_inline(
        described_class.new(container: "my-widget")
      ) do |list|
        list.with_header(title: "Header")
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Box-header#my-widget_header")
    end

    it "derives the header ids when explicit slot ids are provided" do
      rendered = render_inline(
        described_class.new(container: "ignored", id: "explicit-box", collapsible: true)
      ) do |list|
        list.with_header(title: "Header", id: "explicit-header", list_id: "explicit-list")
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Box-header#explicit-box_header")
      expect(rendered).to have_element(aria: { controls: "explicit-box_list" })
      expect(rendered).to have_no_css(".Box-header#explicit-header")
      expect(rendered).to have_no_element(aria: { controls: "explicit-list" })
    end

    it "derives the list id from the explicit box id" do
      rendered = render_inline(
        described_class.new(container: "ignored", id: "explicit-box", list_id: "explicit-list")
      ) do |list|
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Box#explicit-box")
      expect(rendered).to have_css("ul#explicit-box_list")
      expect(rendered).to have_no_css("ul#explicit-list")
    end

    it "derives the footer id from the explicit box id" do
      rendered = render_inline(
        described_class.new(container: "ignored", id: "explicit-box", collapsible: true)
      ) do |list|
        list.with_header(title: "Header")
        list.with_item { "row" }
        list.with_footer(id: "explicit-footer") { "footer" }
      end

      expect(rendered).to have_css(".Box-footer#explicit-box_footer")
      expect(rendered).to have_no_css(".Box-footer#explicit-footer")
      expect(rendered).to have_element(aria: { controls: "explicit-box_list explicit-box_footer" })
    end
  end

  describe "system arguments forwarded to BorderBox" do
    subject(:rendered_component) do
      render_inline(
        described_class.new(
          container: "sys-args",
          classes: "extra-class",
          data: { test_selector: "my-box" }
        )
      ) do |list|
        list.with_item { "row" }
      end
    end

    it "forwards classes to the underlying BorderBox" do
      expect(rendered_component).to have_css(".Box.extra-class")
    end

    it "forwards data attributes to the underlying BorderBox" do
      expect(rendered_component).to have_css(".Box[data-test-selector='my-box']")
    end
  end

  describe "constructor requires container:" do
    it "raises ArgumentError when container: is missing" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end
  end

  describe "collapsible" do
    it "renders a non-collapsible header by default" do
      rendered = render_inline(
        described_class.new(container: "no-collapse")
      ) do |list|
        list.with_header(title: "Non-collapsible header", count: 3) do |header|
          header.with_description { "Description text" }
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_heading("Non-collapsible header", level: 4)
      expect(rendered).to have_css(".Counter", text: "3")
      expect(rendered).to have_text("Description text")
      expect(rendered).to have_no_css("collapsible-header")
      expect(rendered).to have_no_css("[aria-controls]")
    end

    it "renders a collapsible header when collapsible is true" do
      rendered = render_inline(
        described_class.new(container: "explicit-collapse", collapsible: true)
      ) do |list|
        list.with_header(title: "Collapsible header")
        list.with_item { "row" }
      end

      expect(rendered).to have_css("collapsible-header")
    end

    it "adds a collapsible modifier without rendering a grid description container" do
      rendered = render_inline(
        described_class.new(container: "explicit-collapse", collapsible: true)
      ) do |list|
        list.with_header(title: "Collapsible header") do |header|
          header.with_description { "Collapsible description" }
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_css(
        ".op-border-box-list-header.op-border-box-list-header_collapsible"
      )
      expect(rendered).to have_no_css(".op-border-box-list-header--description")
      expect(rendered).to have_text("Collapsible description")
    end
  end

  describe "scheme" do
    it "defaults to :default" do
      rendered = render_inline(
        described_class.new(container: "scheme-default")
      ) do |list|
        list.with_header(title: "Default")
        list.with_item { "row" }
      end

      expect(rendered).to have_no_css(".op-border-box-list_transparent")
    end

    it "applies the transparent CSS class when scheme is :transparent" do
      rendered = render_inline(
        described_class.new(container: "scheme-transparent", scheme: :transparent)
      ) do |list|
        list.with_header(title: "Transparent")
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Box.op-border-box-list_transparent")
    end

    it "keeps collapsible independent of the transparent scheme" do
      rendered = render_inline(
        described_class.new(container: "transparent-collapse", scheme: :transparent, collapsible: true)
      ) do |list|
        list.with_header(title: "Transparent collapsible")
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Box.op-border-box-list_transparent")
      expect(rendered).to have_css("collapsible-header")
    end
  end

  describe "header padding" do
    it "inherits the underlying BorderBox header padding by default" do
      rendered = render_inline(
        described_class.new(container: "header-padding-inherit")
      ) do |list|
        list.with_header(title: "Inherited padding")
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Box.op-border-box-list")
      expect(rendered).to have_no_css("[class*='op-border-box-list_header-padding-']")
    end

    it "adds a header padding modifier when configured" do
      rendered = render_inline(
        described_class.new(container: "header-padding-default", padding: :condensed, header_padding: :default)
      ) do |list|
        list.with_header(title: "Default header padding")
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".Box.Box--condensed.op-border-box-list_header-padding-default")
    end

    it "raises for unsupported values in test" do
      expect do
        described_class.new(container: "header-padding-unsupported", header_padding: :unsupported)
      end.to raise_error Primer::FetchOrFallbackHelper::InvalidValueError
    end
  end
end
