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

    it "renders custom title slot content inside the title heading" do
      rendered = render_inline(
        described_class.new(container: "hdr-title-content")
      ) do |list|
        list.with_header(title: "String title") do |header|
          header.with_title { '<a href="/somewhere">Linked title</a>'.html_safe }
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_heading("Linked title", level: 4)
      expect(rendered)
        .to have_css(".op-border-box-list-header--heading-line h4.Box-title a[href='/somewhere']",
                     text: "Linked title")
      expect(rendered).to have_no_text("String title")
    end

    it "renders header breadcrumbs in the title position with a visually hidden title" do
      rendered = render_inline(
        described_class.new(container: "hdr-breadcrumbs")
      ) do |list|
        list.with_header(title: "Design & Content") do |header|
          header.with_breadcrumbs do |crumbs|
            crumbs.with_item(href: "/departments") { "My Organization" }
            crumbs.with_item(href: "/departments/42") { "Design & Content" }
          end
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_css(
        ".op-border-box-list-header--heading-line nav[aria-label='Breadcrumb'] li.breadcrumb-item",
        count: 2
      )
      expect(rendered).to have_css("h4.Box-title.sr-only", text: "Design & Content", visible: :all)
      expect(rendered).to have_no_css(".op-border-box-list-header--heading-line .Truncate")
    end

    it "keeps the list labelled by a header that contains the title text" do
      rendered = render_inline(
        described_class.new(container: "hdr-breadcrumbs-label")
      ) do |list|
        list.with_header(title: "Design & Content") do |header|
          header.with_breadcrumbs do |crumbs|
            crumbs.with_item(href: "/departments") { "My Organization" }
          end
        end
        list.with_item { "row" }
      end

      labelledby = rendered.css("ul").first["aria-labelledby"]
      expect(labelledby).to be_present
      expect(rendered.css("##{labelledby}").text).to include("Design & Content")
    end

    it "raises when breadcrumbs are combined with a collapsible header" do
      expect do
        render_inline(
          described_class.new(container: "hdr-breadcrumbs-collapsible", collapsible: true)
        ) do |list|
          list.with_header(title: "Title") do |header|
            header.with_breadcrumbs do |crumbs|
              crumbs.with_item(href: "/somewhere") { "Somewhere" }
            end
          end
          list.with_item { "row" }
        end
      end.to raise_error(ArgumentError, /collapsible/)
    end

    it "raises when the header has neither a title nor title slot" do
      expect do
        render_inline(
          described_class.new(container: "hdr-without-title")
        ) do |list|
          list.with_header
          list.with_item { "row" }
        end
      end.to raise_error(ArgumentError, /title/)
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

    it "renders a status label in its own header area" do
      rendered = render_inline(
        described_class.new(container: "hdr-label")
      ) do |list|
        list.with_header(title: "Bug") do |header|
          header.with_label(scheme: :success) { "Enabled" }
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_css(
        ".op-border-box-list-header--label .Label.Label--success",
        text: "Enabled"
      )
      expect(rendered).to have_no_css(".op-border-box-list-header--actions .Label")
    end

    it "renders an action icon button" do
      rendered = render_inline(
        described_class.new(container: "hdr-icon-action")
      ) do |list|
        list.with_header(title: "Actions") do |header|
          header.with_action_icon_button(icon: :pencil, aria: { label: "Edit list" })
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_button(accessible_name: "Edit list")
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

    it "forwards button arguments to the default menu show button" do
      rendered = render_inline(
        described_class.new(container: "hdr-menu-button-arguments")
      ) do |list|
        list.with_header(title: "With configured menu") do |header|
          header.with_menu(
            button_arguments: {
              aria: { label: "Configured actions" },
              data: { test_selector: "configured-actions-button" }
            }
          ) do |menu|
            menu.with_item(label: "Option A", value: "a")
          end
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_button(
        "hdr-menu-button-arguments_list_menu-button",
        accessible_name: "Configured actions"
      )
      expect(rendered).to have_css("button[data-test-selector='configured-actions-button']")
    end

    it "renders a custom show button without adding the default show button" do
      rendered = render_inline(
        described_class.new(container: "hdr-custom-menu")
      ) do |list|
        list.with_header(title: "With custom menu") do |header|
          header.with_menu do |menu|
            menu.with_show_button { "Add link" }
            menu.with_item(label: "Option A", value: "a")
          end
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_css("action-menu")
      expect(rendered).to have_button("Add link")
      expect(rendered).to have_no_css("tool-tip[data-type='label']", text: I18n.t(:label_actions))
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

    it "renders an inline action menu in the actions area" do
      rendered = render_inline(described_class.new(container: "hdr-action-menu")) do |list|
        list.with_header(title: "Sections") do |header|
          header.with_action_menu(test_selector: "position-menu") do |menu|
            menu.with_show_button { "Overview" }
            menu.with_item(label: "Side panel")
          end
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".op-border-box-list-header--actions action-menu[data-test-selector='position-menu']")
    end

    it "lets an inline action menu coexist with the trailing overflow menu" do
      rendered = render_inline(described_class.new(container: "hdr-two-menus")) do |list|
        list.with_header(title: "Sections") do |header|
          header.with_action_menu do |menu|
            menu.with_show_button { "Position" }
            menu.with_item(label: "Side panel")
          end
          header.with_menu do |menu|
            menu.with_item(label: "Edit") { |item| item.with_leading_visual_icon(icon: :pencil) }
          end
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".op-border-box-list-header--actions action-menu")
      expect(rendered).to have_css(".op-border-box-list-header--menu action-menu")
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

      it "applies the Box-card class and the clickable modifier to the work-package card" do
        expect(rendered_component).to have_css(".op-work-package-card.Box-card.Box-card--clickable")
        expect(rendered_component).to have_no_css(".Box-card--draggable")
      end

      it "does not claim Enter activation on the base card (no Enter handler there)" do
        expect(rendered_component).to have_css(".Box-card", aria: { keyshortcuts: nil })
      end

      it "does not make the base card keyboard-focusable (no Enter handler there)" do
        expect(rendered_component).to have_css(".op-work-package-card")
        expect(rendered_component).to have_no_css(".op-work-package-card[tabindex]")
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
    it "renders the default empty state when no items are present" do
      rendered = render_inline(
        described_class.new(container: "default-empty-list")
      ) do |list|
        list.with_header(title: "Empty list")
      end

      expect(rendered).to have_css(".blankslate")
      expect(rendered).to have_heading(I18n.t(:label_nothing_display), level: 4)
      expect(rendered).to have_text(I18n.t(:no_results_title_text))
    end

    it "renders the default empty state without requiring a header" do
      rendered = render_inline(
        described_class.new(container: "default-empty-list-without-header")
      )

      expect(rendered).to have_css(".Box#default-empty-list-without-header")
      expect(rendered).to have_css(".blankslate")
      expect(rendered).to have_heading(I18n.t(:label_nothing_display), level: 4)
    end

    it "renders a call-to-action as the blankslate primary action" do
      rendered = render_inline(
        described_class.new(container: "empty-list-with-action")
      ) do |list|
        list.with_empty_state(
          title: "Nothing here",
          action_label: "Add item",
          action_icon: :plus,
          action_arguments: { href: "/items/new", scheme: :primary }
        )
      end

      expect(rendered).to have_css(".blankslate") do |blankslate|
        expect(blankslate).to have_link("Add item", href: "/items/new") { |link| link.has_css?(".octicon-plus") }
      end
    end

    it "renders no primary action without an action label" do
      rendered = render_inline(
        described_class.new(container: "empty-list-without-action")
      ) do |list|
        list.with_empty_state(title: "Nothing here", action_label: "", action_arguments: { href: "/items/new" })
      end

      expect(rendered).to have_css(".blankslate")
      expect(rendered).to have_no_css(".blankslate a, .blankslate button")
    end

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

    it "omits the empty state when items are present" do
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

    it "sets aria role and live attributes on the default empty state when the list is interactive" do
      rendered = render_inline(
        described_class.new(container: "default-empty-interactive-aria", interactive: true)
      )

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

    it "renders a drop-zone overlay hidden from assistive technology when a drop target label is given" do
      rendered = render_inline(
        described_class.new(container: "empty-drop-zone")
      ) do |list|
        list.with_empty_state(title: "Nothing here", drop_target_label: "Drop items here")
      end

      expect(rendered).to have_css(".op-border-box-list-empty-state") do |empty_state|
        expect(empty_state).to have_css(".blankslate", text: "Nothing here")
        expect(empty_state).to have_css(
          ".op-border-box-list-empty-state--drop-overlay",
          text: "Drop items here",
          aria: { hidden: true }
        )
      end
    end

    it "does not render a drop-zone overlay without a drop target label" do
      rendered = render_inline(
        described_class.new(container: "empty-no-drop-zone")
      ) do |list|
        list.with_empty_state(title: "Nothing here")
      end

      expect(rendered).to have_css(".op-border-box-list-empty-state") do |empty_state|
        expect(empty_state).to have_css(".blankslate")
        expect(empty_state).to have_no_css(".op-border-box-list-empty-state--drop-overlay")
      end
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

  describe "header title" do
    it "renders the title from the title: string" do
      rendered = render_inline(
        described_class.new(container: "hdr-title-string")
      ) do |list|
        list.with_header(title: "String title")
        list.with_item { "row" }
      end

      expect(rendered).to have_heading("String title", level: 4)
    end

    it "renders the title from the with_title slot" do
      rendered = render_inline(
        described_class.new(container: "hdr-title-slot")
      ) do |list|
        list.with_header do |header|
          header.with_title { "Slot title" }
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_heading("Slot title", level: 4)
    end

    it "prefers the with_title slot over the title: string" do
      rendered = render_inline(
        described_class.new(container: "hdr-title-precedence")
      ) do |list|
        list.with_header(title: "String title") do |header|
          header.with_title { "Slot title" }
        end
        list.with_item { "row" }
      end

      expect(rendered).to have_heading("Slot title", level: 4)
      expect(rendered).to have_no_text("String title")
    end

    it "raises when neither the title: string nor the with_title slot is provided" do
      expect do
        render_inline(
          described_class.new(container: "hdr-no-title")
        ) do |list|
          list.with_header(count: 1)
          list.with_item { "row" }
        end
      end.to raise_error(ArgumentError)
    end
  end

  describe "header drag handle" do
    it "renders a drag handle when `show_drag_handle` is true" do
      rendered = render_inline(
        described_class.new(container: "hdr-drag-handle")
      ) do |list|
        list.with_header(title: "Draggable", show_drag_handle: true)
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".op-border-box-list-header--drag_handle .DragHandle")
    end

    it "omits the drag handle by default" do
      rendered = render_inline(
        described_class.new(container: "hdr-no-drag-handle")
      ) do |list|
        list.with_header(title: "Plain")
        list.with_item { "row" }
      end

      expect(rendered).to have_no_css(".op-border-box-list-header--drag_handle")
    end
  end

  describe "empty_state_behavior" do
    it "renders the generic default when static and empty" do
      render_inline(described_class.new(container: "c"))
      expect(page).to have_css("[data-empty-list-item]", text: I18n.t(:label_nothing_display))
    end

    it "renders nothing for the :none behavior when empty" do
      render_inline(described_class.new(container: "c", empty_state_behavior: :none))
      expect(page).to have_no_css("[data-empty-list-item]")
    end

    it "ignores a declared empty state under :none" do
      render_inline(described_class.new(container: "c", empty_state_behavior: :none)) do |list|
        list.with_empty_state(title: "Declared")
      end
      expect(page).to have_no_css("[data-empty-list-item]")
      expect(page).to have_no_text("Declared")
    end

    it "does not render an empty box shell for :none with only a declared empty state" do
      # render? must treat the ignored slot as absent, or a bare bordered Box renders
      render_inline(described_class.new(container: "c", empty_state_behavior: :none)) do |list|
        list.with_empty_state(title: "Declared")
      end
      expect(page).to have_no_css(".Box")
    end

    it "raises for unsupported values in test" do
      # fetch_or_fallback only falls back to :static silently in production;
      # in test/development it raises so an unsupported value is caught early.
      expect do
        described_class.new(container: "c", empty_state_behavior: :bogus)
      end.to raise_error Primer::FetchOrFallbackHelper::InvalidValueError
    end
  end

  describe ":dynamic markup" do
    # Capybara's `have_css` matcher always converts its target through
    # `Capybara.string`, which explicitly strips `<template>` inner HTML
    # (`template.content` is not part of the queryable document per HTML5
    # semantics) before running the selector. That makes it impossible to
    # assert *into* a `<template>` via `page`/`have_css`, no matter what the
    # component renders, so the prototype's markup is asserted directly
    # against the Nokogiri fragment `render_inline` returns instead.
    def template_placeholder(rendered)
      rendered.at_css(
        "template[data-border-box-list-target='emptyStateTemplate'] li[data-empty-list-item='true']"
      )
    end

    it "wraps the box and parks the placeholder in a template when populated" do
      rendered = render_inline(described_class.new(container: "c", empty_state_behavior: :dynamic)) do |list|
        list.with_empty_state(title: "Empty!")
        list.with_item { "Row" }
      end
      expect(page).to have_css("[data-controller='border-box-list'] ul[data-border-box-list-target='list']")
      expect(page).to have_no_css("ul [data-empty-list-item]")
      # legacy generic-drag-and-drop requires the exact value "true"
      placeholder = template_placeholder(rendered)
      expect(placeholder).not_to be_nil
      expect(placeholder.text).to include("Empty!")
    end

    it "renders the placeholder as the real row when empty and keeps a template prototype" do
      rendered = render_inline(described_class.new(container: "c", empty_state_behavior: :dynamic)) do |list|
        list.with_empty_state(title: "Empty!")
      end
      expect(page).to have_css("ul > li[data-empty-list-item='true']", text: "Empty!")
      # the prototype must ALWAYS be in the template, or an initially empty list
      # can never restore its placeholder after an empty -> populated -> empty cycle
      expect(template_placeholder(rendered)).not_to be_nil
    end

    it "defaults the template prototype to the generic empty state when populated with no declared empty state" do
      rendered = render_inline(described_class.new(container: "c", empty_state_behavior: :dynamic)) do |list|
        list.with_item { "Row" }
      end
      # a client-side drain to zero rows must clone a real blankslate, not a
      # contentless placeholder, even though no with_empty_state was declared
      placeholder = template_placeholder(rendered)
      expect(placeholder).not_to be_nil
      expect(placeholder.text).to include(I18n.t(:label_nothing_display))
      expect(page).to have_css("ul > li", count: 1)
      expect(page).to have_no_css("ul [data-empty-list-item]")
    end
  end

  describe "sortable wiring" do
    it "emits list wiring on the box root even for dual-role consumers" do
      # replaced: combining roles now raises; list wiring is always root-mounted
      rendered = render_inline(
        described_class.new(
          container: "sortable-list",
          sortable_list: { type: "custom_field", id: 7, name: "General" }
        )
      ) do |list|
        list.with_item(sortable: { id: 1, label: "Row" }) { "row" }
      end

      expect(rendered).to have_element("div", class: "op-border-box-list") do |box|
        expect(box["data-controller"]).to include("sortable-lists--list")
        expect(box["data-sortable-lists--list-type-value"]).to eq("custom_field")
        expect(box["data-sortable-lists--list-accepted-type-value"]).to eq("custom_field")
        expect(box["data-sortable-lists--list-id-value"]).to eq("7")
        expect(box["data-sortable-lists--list-name-value"]).to eq("General")
      end
      expect(rendered).to have_css("[data-controller~='sortable-lists--list']", count: 1)
      expect(rendered).to have_no_css("ul[data-controller~='sortable-lists--list']")
    end

    it "rejects combining sortable_list: with sortable_item:" do
      expect do
        render_inline(
          described_class.new(
            container: "dual-role",
            sortable_list: { type: "custom_field" },
            sortable_item: { id: 1, type: "section" }
          )
        ) { |list| list.with_item { "row" } }
      end.to raise_error(ArgumentError, /BorderBoxListCollectionComponent/)
    end

    it "defaults a row's item type from the list's accepted type" do
      rendered = render_inline(
        described_class.new(container: "sortable-rows", sortable_list: { type: "sprint", accepted_type: "work_package" })
      ) do |list|
        list.with_item(sortable: { id: 3, label: "Task" }) { "row" }
      end

      expect(rendered).to have_css("li") do |row|
        expect(row["data-controller"]).to include("sortable-lists--item")
        expect(row["data-sortable-lists--item-id-value"]).to eq("3")
        expect(row["data-sortable-lists--item-type-value"]).to eq("work_package")
        expect(row["data-sortable-lists--item-label-value"]).to eq("Task")
      end
    end

    it "defaults a row's item type from the list type when no accepted type is given" do
      rendered = render_inline(
        described_class.new(container: "sortable-rows-sym", sortable_list: { type: "custom_field" })
      ) do |list|
        list.with_item(sortable: { id: 4 }) { "row" }
      end

      expect(rendered).to have_css("li[data-sortable-lists--item-type-value='custom_field']")
    end

    it "raises when hand-wired sortable keys on a row conflict with generated wiring" do
      expect do
        render_inline(
          described_class.new(container: "sortable-row-conflict", sortable_list: { type: "custom_field" })
        ) do |list|
          list.with_item(sortable: { id: 5 }, data: { sortable_lists__item_id_value: 99 }) { "row" }
        end
      end.to raise_error(ArgumentError, /sortable_lists__item_id_value/)
    end

    it "emits box-item wiring with a preview target and wires the header drag handle" do
      rendered = render_inline(
        described_class.new(
          container: "sortable-box",
          sortable_item: { id: 9, type: "section", label: "Marketing" }
        )
      ) do |list|
        list.with_header(title: "Marketing", show_drag_handle: true)
        list.with_item { "row" }
      end

      expect(rendered).to have_element("div", class: "op-border-box-list") do |box|
        expect(box["data-controller"]).to include("sortable-lists--item")
        expect(box["data-sortable-lists--item-id-value"]).to eq("9")
        expect(box["data-sortable-lists--item-type-value"]).to eq("section")
        expect(box["data-sortable-lists--item-target"]).to include("preview")
      end
      expect(rendered).to have_css(
        ".op-border-box-list-header--drag_handle .handle[data-sortable-lists--item-target~='handle']"
      )
    end

    it "emits handle and preview targets without an item controller for sortable_handle" do
      rendered = render_inline(
        described_class.new(container: "handle-only", sortable_list: { type: "custom_field" }, sortable_handle: true)
      ) do |list|
        list.with_header(title: "Section", show_drag_handle: true)
        list.with_item { "row" }
      end

      expect(rendered).to have_element("div", class: "op-border-box-list") do |box|
        expect(box["data-sortable-lists--item-target"]).to include("preview")
        expect(box["data-controller"]).not_to include("sortable-lists--item")
      end
      expect(rendered).to have_css(".Box-header .handle[data-sortable-lists--item-target~='handle']")
    end

    it "rejects sortable_handle without a drag-handle-showing header" do
      expect do
        render_inline(
          described_class.new(container: "handle-orphan", sortable_handle: true)
        ) { |list| list.with_item { "row" } }
      end.to raise_error(ArgumentError, /show_drag_handle/)
    end

    it "rejects sortable_handle combined with sortable_item" do
      expect do
        render_inline(
          described_class.new(container: "handle-redundant", sortable_item: { id: 1, type: "x" }, sortable_handle: true)
        ) { |list| list.with_item { "row" } }
      end.to raise_error(ArgumentError, /sortable_item/)
    end

    it "token-merges configured and role-added targets into one attribute" do
      rendered = render_inline(
        described_class.new(
          container: "sortable-targets",
          sortable_item: { id: 2, type: "section", targets: %w[moveMenu preview] }
        )
      ) do |list|
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".op-border-box-list[data-sortable-lists--item-target='moveMenu preview']")
    end

    it "preserves caller data and combines controller tokens without mutating the caller hash" do
      caller_data = { controller: "other-controller", test_selector: "kept" }
      rendered = render_inline(
        described_class.new(
          container: "sortable-merge",
          sortable_item: { id: 4, type: "section" },
          data: caller_data
        )
      ) do |list|
        list.with_item { "row" }
      end

      expect(rendered).to have_css(".op-border-box-list") do |box|
        expect(box["data-controller"]).to include("other-controller")
        expect(box["data-controller"]).to include("sortable-lists--item")
        expect(box["data-test-selector"]).to eq("kept")
      end
      expect(caller_data).to eq(controller: "other-controller", test_selector: "kept")
    end

    it "raises when hand-wired sortable keys conflict with generated wiring" do
      expect do
        render_inline(
          described_class.new(
            container: "sortable-conflict",
            sortable_item: { id: 4, type: "section" },
            data: { sortable_lists__item_id_value: 99 }
          )
        ) { |list| list.with_item { "row" } }
      end.to raise_error(ArgumentError, /sortable_lists__item_id_value/)
    end

    it "raises when a string-keyed hand-wired sortable key conflicts with generated wiring" do
      expect do
        render_inline(
          described_class.new(
            container: "sortable-conflict-string-key",
            sortable_item: { id: 4, type: "section" },
            data: { "sortable_lists__item_id_value" => 99 }
          )
        ) { |list| list.with_item { "row" } }
      end.to raise_error(ArgumentError, /sortable_lists__item_id_value/)
    end

    it "raises for a sortable row without a sortable_list" do
      expect do
        render_inline(described_class.new(container: "sortable-orphan")) do |list|
          list.with_item(sortable: { id: 1, type: "x" }) { "row" }
        end
      end.to raise_error(ArgumentError, /sortable_list/)
    end

    it "defaults the empty-state drop target label from the list name" do
      rendered = render_inline(
        described_class.new(container: "sortable-empty", sortable_list: { type: "custom_field", name: "General" })
      )

      # The empty-state slot renders the supplied drop_target_label string
      # directly (border_box_list_component.rb:145,:160) — no i18n involved;
      # the default is the list's name verbatim. Assert on the overlay node
      # itself, since "General" also appears in the list's own data
      # attributes and would make a bare text-inclusion check vacuous.
      expect(rendered).to have_css(".op-border-box-list-empty-state--drop-overlay", text: "General")
    end

    it "accepts value objects directly" do
      rendered = render_inline(
        described_class.new(
          container: "sortable-objects",
          sortable_list: OpPrimer::SortableLists::List.new(type: "custom_field")
        )
      ) do |list|
        list.with_item(sortable: OpPrimer::SortableLists::Item.new(id: 1, type: "custom_field")) { "row" }
      end

      expect(rendered).to have_css("li[data-controller~='sortable-lists--item']")
    end
  end
end
