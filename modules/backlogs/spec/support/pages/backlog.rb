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

require "support/pages/page"
require "json"

module Pages
  class Backlog < Page
    attr_reader :project

    def initialize(project)
      super()
      @project = project
    end

    def visit!
      super

      expect(page).to have_css("turbo-frame#backlogs_container", wait: 10)
      expect(page).to have_css("#owner_backlogs_container", wait: 10)
      expect(page).to have_css("#sprint_backlogs_container", wait: 10)
      wait_for_backlogs_network_idle
    end

    def path
      project_backlogs_backlog_path(project)
    end

    def expect_inbox_blankslate
      within_backlog_inbox do
        expect(page).to have_css("h4", text: "Backlog inbox is empty")
      end
    end

    def expect_no_inbox_blankslate
      within_backlog_inbox do
        expect(page).to have_no_css("h4", text: "Backlog inbox is empty")
      end
    end

    def expect_backlog_bucket_blankslate(bucket)
      within_backlog_bucket(bucket) do
        expect(page).to have_selector(:heading, level: 4, text: "Backlog bucket is empty")
      end
    end

    def expect_no_backlog_bucket_blankslate(bucket)
      within_backlog_bucket(bucket) do
        expect(page).to have_no_selector(:heading, level: 4, text: "Backlog bucket is empty")
      end
    end

    def expect_sprints_blankslate
      within_sprint_backlogs do
        expect(page).to have_css("h4", text: "No sprints present yet")
      end
    end

    def expect_sprints_blankslate_description(text)
      within_sprint_backlogs do
        expect(page).to have_text(text)
      end
    end

    def expect_no_sprints_blankslate
      within_sprint_backlogs do
        expect(page).to have_no_css("h4", text: "No sprints present yet")
      end
    end

    alias_method :expect_backlog_blankslate, :expect_sprints_blankslate
    alias_method :expect_backlog_blankslate_description, :expect_sprints_blankslate_description
    alias_method :expect_no_backlog_blankslate, :expect_no_sprints_blankslate

    def expect_backlog_settings_link
      within_sprint_backlogs do
        expect(page).to have_link(
          "project settings",
          href: project_settings_backlog_sharing_path(project)
        )
      end
    end

    def expect_no_backlog_settings_link
      within_sprint_backlogs do
        expect(page).to have_no_link(
          "project settings",
          href: project_settings_backlog_sharing_path(project)
        )
      end
    end

    def expect_new_sprint_button
      within_sprint_backlogs do
        expect(page).to have_css(
          test_selector("op-sprints--new-sprint-button"),
          text: Sprint.human_model_name
        )
      end
    end

    def expect_no_new_sprint_button
      within_sprint_backlogs do
        expect(page).to have_no_css(
          test_selector("op-sprints--new-sprint-button"),
          text: Sprint.human_model_name
        )
      end
    end

    def expect_inbox_item(work_package)
      within_backlog_inbox do
        expect(page).to have_css(work_package_selector(work_package))
      end
    end

    def expect_no_inbox_item(work_package)
      within_backlog_inbox do
        expect(page).to have_no_css(work_package_selector(work_package))
      end
    end

    def expect_inbox_show_more
      within_backlog_inbox do
        expect(page).to have_css("#inbox_project_#{project.id}_show_more")
      end
    end

    def expect_no_inbox_show_more
      wait_for_backlogs_network_idle
      within_backlog_inbox do
        expect(page).to have_no_css("#inbox_project_#{project.id}_show_more")
      end
    end

    def click_inbox_show_more
      within_backlog_inbox do
        find("#inbox_project_#{project.id}_show_more").click
      end
      wait_for_backlogs_network_idle
    end

    def expect_work_packages_in_inbox_in_order(work_packages: [])
      within_backlog_inbox do
        expect_work_packages_in_order work_packages:
      end
    end

    def expect_work_packages_in_backlog_bucket_in_order(bucket, work_packages: [])
      within_backlog_bucket(bucket) do
        expect_work_packages_in_order work_packages:
      end
    end

    def expect_work_packages_in_sprint_in_order(sprint,
                                                work_packages: [])
      within_sprint(sprint) do
        expect_work_packages_in_order work_packages:
      end
    end

    def expect_work_packages_in_order(work_packages: [])
      raise ArgumentError, "work_packages should not be empty" if work_packages.empty?

      selectors = work_packages.map { |wp| work_package_selector(wp) }
      expect(page)
        .to have_css(selectors.join(" + "))
      wait_for_backlogs_network_idle
    end

    def sprint_items_in_visual_order(sprint, *work_packages)
      tops = within_sprint(sprint) do
        work_packages.index_with do |wp|
          page.evaluate_script(
            "document.querySelector('#{work_package_selector(wp)}').getBoundingClientRect().top"
          )
        end
      end

      work_packages.sort_by { |wp| tops.fetch(wp) }
    end

    def expect_sprint_names_in_order(*sprint_names)
      expect(sprint_names_in_order).to eq(sprint_names)
    end

    def expect_sprint_heading_with_goal(sprint_name, goal_text)
      within(:section, sprint_name) do
        expect(page)
          .to have_heading(sprint_name, level: 4, accessible_description: goal_text, exact: true)
      end
    end

    def expect_sprint_heading_without_goal(sprint_name)
      within(:section, sprint_name) do
        expect(page)
          .to have_heading(sprint_name, level: 4, accessible_description: "", exact: true)
      end
    end

    def expect_sprint_story_points(sprint, points)
      within(sprint_selector(sprint)) do
        expect(page).to have_css(".velocity", text: points.to_s)
      end
    end

    def expect_sprint_work_package_count(sprint, count)
      within(sprint_selector(sprint)) do
        expect(page).to have_css(
          ".Counter",
          accessible_name: I18n.t(:label_x_work_packages, count:)
        )
      end
    end

    def expect_work_package_in_sprint(work_package, sprint)
      within_sprint(sprint) do
        expect(page)
          .to have_selector(work_package_selector(work_package).to_s)
      end
    end

    def expect_work_package_text_in_sprint(work_package, sprint, text)
      within_sprint(sprint) do
        expect(page)
          .to have_selector(work_package_selector(work_package).to_s, text:)
      end
    end

    def expect_work_package_not_in_sprint(work_package, sprint)
      within_sprint(sprint) do
        expect(page)
          .to have_no_selector(work_package_selector(work_package).to_s)
      end
    end

    def expect_bucket_names_in_order(*bucket_names)
      expect(bucket_names_in_order).to eq(bucket_names)
    end

    def expect_work_package_in_backlog_bucket(work_package, bucket)
      within_backlog_bucket(bucket) do
        expect(page).to have_css(work_package_selector(work_package))
      end
    end

    def expect_backlog_bucket_work_package_count(bucket, count)
      within_backlog_bucket(bucket) do
        expect(page).to have_css(
          ".Counter",
          accessible_name: I18n.t(:label_x_work_packages, count:)
        )
      end
    end

    def expect_work_package_not_in_backlog_bucket(work_package, bucket)
      within_backlog_bucket(bucket) do
        expect(page).to have_no_css(work_package_selector(work_package))
      end
    end

    def within_sprint_menu(sprint, &)
      within_sprint(sprint) do
        button = find(:button, accessible_name: "Sprint actions")
        within(open_controlled_menu(button), &)
      end

      dismiss_menu(sprint)
    end

    def click_in_sprint_menu(sprint, item_name)
      within_sprint_menu(sprint) do |menu|
        menu.find(:menuitem, text: item_name).click
      end
    end

    def within_backlog_bucket_menu(bucket, &)
      within_backlog_bucket(bucket) do
        button = find(:button, accessible_name: "Backlog bucket actions")
        within(open_controlled_menu(button), &)
      end
      dismiss_menu(bucket)
    end

    def click_in_backlog_bucket_menu(bucket, item_name)
      within_backlog_bucket_menu(bucket) do |menu|
        menu.find(:menuitem, text: item_name).click
      end
    end

    def within_work_package_menu(work_package, &)
      within_work_package(work_package) do
        button = find(:button, accessible_name: "Work package actions")
        within(open_controlled_menu(button), &)
      end

      dismiss_menu(work_package)
    end

    def click_in_work_package_menu(work_package, item_name, wait: true)
      within_work_package_menu(work_package) do |submenu|
        wait_for_turbo_stream(wait:) do
          submenu.find(:menuitem, text: item_name).click
        end
      end
    end

    def within_work_package_move_submenu(work_package, &)
      within_work_package_menu(work_package) do |menu|
        yield open_move_submenu(menu)
      end
    end

    def click_in_work_package_move_submenu(work_package, item_name, wait: true)
      within_work_package_move_submenu(work_package) do |submenu|
        wait_for_backlogs_turbo_stream(wait:) do
          submenu.find(:menuitem, text: item_name, visible: :all).click
        end
      end
    end

    alias_method :click_in_inbox_move_menu, :click_in_work_package_move_submenu
    alias_method :click_in_sprint_story_move_menu, :click_in_work_package_move_submenu

    def expect_no_backlog_bucket_menu(bucket)
      within_backlog_bucket(bucket) do
        expect(page).to have_no_button(accessible_name: "Backlog bucket actions")
      end
    end

    def expect_no_sprint_menu(sprint)
      within_sprint(sprint) do
        expect(page).to have_no_button(accessible_name: "Sprint actions")
      end
    end

    def expect_no_sprint_menu_item(sprint, item_name)
      within_sprint_menu(sprint) do |_menu|
        expect(page)
          .to have_no_selector(:menuitem, text: item_name)
      end
    end

    def open_work_package_details(work_package)
      within_work_package(work_package) do
        button = find(:button, accessible_name: "Work package actions")
        open_controlled_menu(button).find(:menuitem, text: I18n.t(:"js.button_open_details")).click
      end
      expect_details_view(work_package)
    end

    def expect_details_view(work_package)
      details_view = Pages::PrimerizedSplitWorkPackage.new(work_package)
      details_view.expect_tab :overview
      details_view.expect_subject

      expect(page).to have_current_path project_backlogs_backlog_details_path(work_package.project, work_package),
                                        ignore_query: true
      wait_for_backlogs_network_idle

      details_view
    end

    def expect_create_work_package_dialog
      expect(page).to have_css("#create-work-package-dialog")
    end

    def expect_sprint(sprint)
      expect(page).to have_css(sprint_selector(sprint))
    end

    def expect_no_sprint(sprint)
      expect(page).to have_no_css(sprint_selector(sprint))
    end

    def open_create_bucket_dialog
      within_owner_backlogs do
        click_on accessible_name: "New backlog bucket"
      end
    end

    def expect_new_backlog_bucket_button
      within_owner_backlogs do
        expect(page).to have_link(BacklogBucket.human_model_name, exact: true)
      end
    end

    def expect_no_new_backlog_bucket_button
      within_owner_backlogs do
        expect(page).to have_no_link(BacklogBucket.human_model_name, exact: true)
      end
    end

    def expect_backlog_bucket(bucket)
      expect(page).to have_css(bucket_selector(bucket))
    end

    def expect_no_backlog_bucket(bucket)
      expect(page).to have_no_css(bucket_selector(bucket))
    end

    def expect_bucket_dialog
      expect(page).to have_dialog(I18n.t(:label_backlog_bucket_new))
    end

    def expect_and_confirm_backlog_bucket_delete_modal
      expect(page).to have_selector backlog_bucket_destroy_modal_selector

      within backlog_bucket_destroy_modal_selector do
        click_button "Delete"
      end
    end

    def expect_work_package_not_draggable(work_package)
      expect(page)
        .to have_no_css(draggable_work_package_selector(work_package))
    end

    def pick_up_and_release_work_package(work_package)
      loop do
        moved_element = find(draggable_work_package_selector(work_package))

        begin
          install_backlogs_move_request_probe
          pick_up_and_release_backlogs_item(moved_element)
          return
        rescue Capybara::Cuprite::ObsoleteNode
          next
        ensure
          stop_backlogs_move_request_probe
        end
      end
    end

    def apply_sprint_filter(*sprints)
      within_sprint_backlogs do
        find_test_selector("sprint_filter_button").click
      end
      within_dialog "Select items" do
        sprints.each { |sprint| click_on sprint.name, role: "option" }
        click_on "Apply"
      end
      wait_for_network_idle
    end

    def apply_bucket_filter(*buckets, include_inbox: false)
      within_owner_backlogs do
        find_test_selector("backlog_bucket_filter_button").click
      end
      within_dialog "Select items" do
        buckets.each { |bucket| click_on bucket.name, role: "option" }
        click_on(I18n.t(:label_inbox), role: "option") if include_inbox
        click_on "Apply"
      end
      wait_for_network_idle
    end

    def expect_inbox
      expect(page).to have_test_selector("backlog-inbox")
    end

    def expect_no_inbox
      expect(page).to have_no_test_selector("backlog-inbox")
    end

    def within_filter_panel(type, &)
      within_filter_container(type) do
        find_test_selector(filter_button_label(type)).click
      end
      within_dialog("Select items", &)
    end

    def clear_filter(type)
      within_filter_panel(type) { click_on I18n.t(:button_clear) }
      wait_for_network_idle
    end

    def expect_filter_count(type, count)
      within_filter_container(type) do
        within_test_selector(filter_button_label(type)) do
          expect(page).to have_css(".Counter", text: count)
        end
      end
    end

    def expect_no_backlogs_move_request
      move_requests = page.evaluate_script("window.__opBacklogsMoveRequestProbe?.requests ?? []")

      expect(move_requests).to be_empty
    ensure
      stop_backlogs_move_request_probe
    end

    def expect_backlogs_drop_handled_without_item_target
      drop_summary = page.evaluate_script(<<~JS)
        (() => {
          const call = window.__opBacklogsDndProbeState?.handleDropCalls?.at(-1);

          return {
            handled: Boolean(call),
            dropTargetTypes: call?.dropTargets?.map((target) => target.data?.entries?.type) ?? []
          };
        })()
      JS

      expect(drop_summary.fetch("handled")).to be(true)
      expect(drop_summary.fetch("dropTargetTypes")).to include("backlog_bucket")
      expect(drop_summary.fetch("dropTargetTypes")).not_to include("work_package")
    end

    def expect_no_filter_count(type)
      within_filter_container(type) do
        within_test_selector(filter_button_label(type)) do
          expect(page).to have_no_css(".Counter")
        end
      end
    end

    def drag_work_package(moved, before: nil, into: nil)
      raise ArgumentError, "You must specify either before or into" unless before.present? ^ into.present?

      moved_element = find(draggable_work_package_selector(moved))
      target_element = if before
                         find(work_package_selector(before))
                       else
                         find(sprint_selector(into))
                       end

      wait_for_backlogs_turbo_stream do
        drag_backlogs_item(source: moved_element, target: target_element, edge: before ? :top : nil)
      end
    rescue Capybara::Cuprite::ObsoleteNode
      retry
    end

    def drag_work_package_to_backlog_inbox(work_package)
      moved_element = find(draggable_work_package_selector(work_package))
      inbox = find(backlog_inbox_selector)
      target_item = inbox.all("[data-sortable-lists--item-id-value]", minimum: 0).last
      target_element = target_item || inbox.find("[data-empty-list-item]")

      wait_for_backlogs_turbo_stream do
        drag_backlogs_item(source: moved_element, target: target_element, edge: target_item ? :bottom : nil)
      end
      wait_for { work_package.reload.backlog_bucket_id }.to be_nil
      wait_for { work_package.reload.sprint_id }.to be_nil
    rescue Capybara::Cuprite::ObsoleteNode
      retry
    end

    def drag_work_package_to_backlog_bucket(work_package, bucket)
      moved_element = find(draggable_work_package_selector(work_package))
      target_element = find(list_body_selector(bucket_selector(bucket)))

      wait_for_backlogs_turbo_stream do
        drag_backlogs_item(source: moved_element, target: target_element)
      end
      wait_for { work_package.reload.backlog_bucket_id }.to eq(bucket.id)
    rescue Capybara::Cuprite::ObsoleteNode
      retry
    end

    def drag_work_package_to_sprint(work_package, sprint)
      moved_element = find(draggable_work_package_selector(work_package))
      target_element = find(list_body_selector(sprint_selector(sprint)))
      wait_for_backlogs_turbo_stream do
        drag_backlogs_item(source: moved_element, target: target_element)
      end
      wait_for { work_package.reload.sprint_id }.to eq(sprint.id)
    rescue Capybara::Cuprite::ObsoleteNode
      retry
    end

    def open_create_sprint_dialog
      find_test_selector("op-sprints--new-sprint-button", text: "Sprint").click
    end

    def expect_sprint_dialog
      expect(page).to have_css("#sprint-dialog")
    end

    def click_start_sprint_button(sprint)
      within_sprint(sprint) do
        click_on("Start")
      end
    end

    def click_complete_sprint_button(sprint)
      within_sprint(sprint) do
        click_on("Complete")
      end
    end

    def click_to_complete_sprint(sprint)
      click_complete_sprint_button(sprint)
    end

    def expect_sprint_completing_modal
      expect(page).to have_css sprint_complete_modal_selector
    end

    def expect_sprints_to_choose_for_moving_unfinished_work_packages_to(*sprints)
      within sprint_complete_modal_selector do
        expect(page).to have_select("Select sprint", options: sprints.map(&:name))
      end
    end

    def choose_to_move_unfinished_work_packages_to_sprint(sprint_name)
      within sprint_complete_modal_selector do
        choose I18n.t("backlogs.finish_sprint_dialog_component.actions.move_to_sprint")
        select sprint_name, from: "Select sprint"

        click_button "Complete sprint"
      end
    end

    def choose_to_move_unfinished_work_packages_to_top_of_backlog
      within sprint_complete_modal_selector do
        choose I18n.t("backlogs.finish_sprint_dialog_component.actions.move_to_top_of_backlog")

        click_button "Complete sprint"
      end
    end

    def choose_to_move_unfinished_work_packages_to_bottom_of_backlog
      within sprint_complete_modal_selector do
        choose I18n.t("backlogs.finish_sprint_dialog_component.actions.move_to_bottom_of_backlog")

        click_button "Complete sprint"
      end
    end

    def expect_and_dismiss_error(message)
      expect(page).to have_text message

      click_on "Cancel"
    end

    def within_work_package(work_package, &)
      within(work_package_selector(work_package), &)
    end

    private

    def within_sprint(sprint, &)
      within(sprint_selector(sprint), &)
    end

    def within_backlog_bucket(bucket, &)
      within(bucket_selector(bucket), &)
    end

    def within_backlog_inbox(&)
      within(backlog_inbox_selector, &)
    end

    def within_owner_backlogs(&)
      within("#owner_backlogs_container", &)
    end

    def within_sprint_backlogs(&)
      within("#sprint_backlogs_container", &)
    end

    def within_filter_container(type, &)
      type == :sprint ? within_sprint_backlogs(&) : within_owner_backlogs(&)
    end

    def filter_button_label(type)
      type == :sprint ? "sprint_filter_button" : "backlog_bucket_filter_button"
    end

    def sprint_selector(sprint)
      test_selector("sprint-#{sprint.id}")
    end

    def bucket_selector(bucket)
      raise ArgumentError, "bucket must be persisted" unless bucket.persisted?

      test_selector("backlog-bucket-#{bucket.id}")
    end

    def backlog_inbox_selector
      test_selector("backlog-inbox")
    end

    def list_body_selector(container_selector)
      "#{container_selector} > ul"
    end

    def work_package_selector(work_package)
      test_selector("work-package-#{work_package.id}")
    end

    def draggable_work_package_selector(work_package)
      "#{work_package_selector(work_package)}[data-sortable-lists--item-id-value]"
    end

    def drag_backlogs_item(source:, target:, edge: nil)
      if selenium_driver?
        selenium_drag_backlogs_item(source:, target:, edge:)
      else
        source.native.drag_to(target.native, delay: 0.1)
      end
    end

    def pick_up_and_release_backlogs_item(source)
      install_backlogs_dnd_probe(source:, target: source, edge: nil)

      scroll_to_element(source)

      if selenium_driver?
        page
          .driver
          .browser
          .action
          .move_to(source.native)
          .click_and_hold
          .pause(duration: 0.1)
          .move_by(0, 8)
          .pause(duration: 0.1)
          .release
          .perform
      else
        source.native.drag_to(source.native, delay: 0.1)
      end

      # Assert Pragmatic DnD tore down its own honey-pot overlay before we force
      # a cleanup, so a regression that leaves the overlay stuck is caught here
      # instead of being masked by the JS removal below.
      expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
      clear_pragmatic_dnd_honey_pot
    end

    def selenium_drag_backlogs_item(source:, target:, edge: nil)
      install_backlogs_dnd_probe(source:, target:, edge:)

      scroll_to_element(source)

      source_rect = source.native.rect
      target_rect = target.native.rect
      target_x, target_y = selenium_target_point(target_rect, edge:)
      source_x, source_y = selenium_element_center(source_rect)

      page
        .driver
        .browser
        .action
        .move_to(source.native)
        .click_and_hold(source.native)
        .pause(duration: 0.1)
        .move_by(target_x - source_x, target_y - source_y)
        .pause(duration: 0.1)
        .release
        .perform

      # Assert Pragmatic DnD tore down its own honey-pot overlay before we force
      # a cleanup, so a regression that leaves the overlay stuck is caught here
      # instead of being masked by the JS removal below.
      expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
      clear_pragmatic_dnd_honey_pot
    end

    def selenium_target_point(rect, edge:)
      offset = [6, rect.height / 4].min

      [
        rect.x + (rect.width / 2),
        case edge
        when :top
          rect.y + offset
        when :bottom
          rect.y + rect.height - offset
        else
          rect.y + (rect.height / 2)
        end
      ].map(&:round)
    end

    def selenium_element_center(rect)
      [
        rect.x + (rect.width / 2),
        rect.y + (rect.height / 2)
      ].map(&:round)
    end

    def wait_for_backlogs_network_idle
      wait_for_network_idle if using_cuprite?
    end

    def wait_for_backlogs_turbo_stream(wait: 10, &)
      return yield unless wait
      return wait_for_turbo_stream(wait:, &) if using_cuprite?

      timeout = wait == true ? 10 : wait
      timeout_ms = timeout * 1000
      page.execute_script(<<~JS, timeout_ms)
        window.__opBacklogsTurboStreamAbort?.abort();

        const controller = new AbortController();
        const state = {
          rendered: false,
          timeoutMs: arguments[0],
          events: []
        };

        document.addEventListener('op:turbo-stream-rendered', (event) => {
          state.rendered = true;
          state.events.push({
            type: event.type,
            time: Math.round(performance.now())
          });
        }, { signal: controller.signal });

        window.__opBacklogsTurboStreamAbort = controller;
        window.__opBacklogsTurboStreamState = state;
      JS

      yield

      wait_for_backlogs_turbo_stream_event(timeout:)
    ensure
      stop_backlogs_turbo_stream_probe unless using_cuprite?
    end

    def wait_for_backlogs_turbo_stream_event(timeout:)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

      loop do
        return if page.evaluate_script("window.__opBacklogsTurboStreamState?.rendered === true")

        if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          raise "wait_for_backlogs_turbo_stream: no turbo stream rendered\n#{backlogs_dnd_diagnostics}"
        end

        sleep 0.05
      end
    end

    def stop_backlogs_turbo_stream_probe
      page.execute_script("window.__opBacklogsTurboStreamAbort?.abort();")
    end

    def install_backlogs_dnd_probe(source:, target:, edge:)
      page.execute_script(<<~JS, source, target, edge&.to_s)
        window.__opBacklogsDndProbeAbort?.abort();

        const controller = new AbortController();
        const sourceElement = arguments[0];
        const targetElement = arguments[1];
        const state = {
          source: describeElement(sourceElement),
          target: describeElement(targetElement),
          requestedEdge: arguments[2],
          events: [],
          handleDropCalls: [],
          snapshots: []
        };

        function itemIdFor(element) {
          const closestItem = element?.closest?.('[data-sortable-lists--item-id-value]');
          const descendantItem = element?.querySelector?.('[data-sortable-lists--item-id-value]');

          return (closestItem ?? descendantItem)
            ?.getAttribute('data-sortable-lists--item-id-value') ?? null;
        }

        function backlogsItemFor(element) {
          return element?.closest?.('[data-sortable-lists--item-id-value]') ??
            element?.querySelector?.('[data-sortable-lists--item-id-value]') ??
            null;
        }

        function controllerInfo(element) {
          const item = backlogsItemFor(element);
          const application = window.Stimulus;

          if (!item || !application?.getControllerForElementAndIdentifier) {
            return { available: false };
          }

          const controller = application.getControllerForElementAndIdentifier(item, 'sortable-lists--item');

          return {
            available: true,
            connected: Boolean(controller),
            idValue: controller?.idValue ?? null,
            hasCleanupFn: Boolean(controller?.cleanupFn)
          };
        }

        function dataSummary(data) {
          if (!data || typeof data !== 'object') {
            return data ?? null;
          }

          const entries = Object.fromEntries(Object.entries(data));
          const symbols = Object.getOwnPropertySymbols(data).map((symbol) => ({
            description: symbol.description,
            value: data[symbol]
          }));

          return { entries, symbols };
        }

        function dropTargetSummary(dropTarget) {
          return {
            data: dataSummary(dropTarget.data),
            element: describeElement(dropTarget.element)
          };
        }

        function patchSortableListsController() {
          const application = window.Stimulus;
          const root = sourceElement.closest('[data-controller~="sortable-lists"]');
          const sortableListsController = root && application?.getControllerForElementAndIdentifier
            ? application.getControllerForElementAndIdentifier(root, 'sortable-lists')
            : null;

          state.sortableListsController = {
            rootFound: Boolean(root),
            connected: Boolean(sortableListsController),
            patched: false
          };

          if (!sortableListsController?.handleDrop || sortableListsController.__opBacklogsDndProbePatched) {
            return;
          }

          const originalHandleDrop = sortableListsController.handleDrop.bind(sortableListsController);

          sortableListsController.handleDrop = (payload) => {
            state.handleDropCalls.push({
              source: {
                data: dataSummary(payload.source?.data),
                element: describeElement(payload.source?.element)
              },
              dropTargets: payload.location?.current?.dropTargets?.map(dropTargetSummary) ?? [],
              input: payload.location?.current?.input ?? null,
              time: Math.round(performance.now())
            });

            return originalHandleDrop(payload);
          };

          sortableListsController.__opBacklogsDndProbePatched = true;
          state.sortableListsController.patched = true;
        }

        function describeElement(element) {
          if (!element) {
            return { found: false };
          }

          const rect = element.getBoundingClientRect();
          const item = backlogsItemFor(element);
          const row = element.closest?.('.Box-row');

          return {
            found: true,
            tagName: element.tagName,
            itemId: itemIdFor(element),
            testSelector: element.closest?.('[data-test-selector]')?.getAttribute('data-test-selector') ?? null,
            itemTagName: item?.tagName ?? null,
            draggable: item?.draggable ?? element.draggable,
            draggableAttribute: item?.getAttribute('draggable') ?? element.getAttribute('draggable'),
            dataDropTargetForElement: item?.getAttribute('data-drop-target-for-element') ??
              element.getAttribute('data-drop-target-for-element'),
            controller: controllerInfo(element),
            rowClassName: row?.className ?? null,
            rect: {
              x: Math.round(rect.x),
              y: Math.round(rect.y),
              width: Math.round(rect.width),
              height: Math.round(rect.height)
            }
          };
        }

        function snapshot(label) {
          state.snapshots.push({
            label,
            draggingCount: document.querySelectorAll('[data-dragging]').length,
            honeyPotCount: document.querySelectorAll('[data-pdnd-honey-pot]').length,
            dropTargets: document.querySelectorAll('[data-drop-target-for-element]').length,
            dropPositions: Array
              .from(document.querySelectorAll('[data-drop-position]'))
              .map((element) => ({
                itemId: itemIdFor(element),
                position: element.getAttribute('data-drop-position')
              })),
            source: describeElement(sourceElement),
            target: describeElement(targetElement),
            time: Math.round(performance.now())
          });
        }

        function pushEvent(event) {
          const elementsFromPoint = event.clientX == null || event.clientY == null
            ? []
            : Array
              .from(document.elementsFromPoint(event.clientX, event.clientY))
              .slice(0, 6)
              .map(describeElement);

          state.events.push({
            type: event.type,
            targetItemId: itemIdFor(event.target),
            clientX: event.clientX,
            clientY: event.clientY,
            defaultPrevented: event.defaultPrevented,
            dropEffect: event.dataTransfer?.dropEffect ?? null,
            effectAllowed: event.dataTransfer?.effectAllowed ?? null,
            draggingCount: document.querySelectorAll('[data-dragging]').length,
            honeyPotCount: document.querySelectorAll('[data-pdnd-honey-pot]').length,
            dropPositions: Array
              .from(document.querySelectorAll('[data-drop-position]'))
              .map((element) => ({
                itemId: itemIdFor(element),
                position: element.getAttribute('data-drop-position')
              })),
            elementsFromPoint,
            time: Math.round(performance.now())
          });

          if (state.events.length > 100) {
            state.events.shift();
          }
        }

        ['mousedown', 'mousemove', 'mouseup', 'dragstart', 'dragenter', 'dragover', 'dragleave', 'drop', 'dragend']
          .forEach((type) => document.addEventListener(type, pushEvent, {
            capture: true,
            signal: controller.signal
          }));

        patchSortableListsController();
        snapshot('before-drag');

        window.__opBacklogsDndProbeAbort = controller;
        window.__opBacklogsDndProbeState = state;
      JS
    end

    def install_backlogs_move_request_probe
      page.execute_script(<<~JS)
        window.__opBacklogsMoveRequestProbe = { requests: [] };

        if (!window.__opBacklogsOriginalFetch) {
          window.__opBacklogsOriginalFetch = window.fetch;
        }

        window.fetch = (...args) => {
          const request = args[0];
          const options = args[1] ?? {};
          const url = String(request?.url ?? request);
          const method = String(request?.method ?? options.method ?? 'GET').toUpperCase();

          if (method === 'PUT' && url.includes('/backlogs/')) {
            window.__opBacklogsMoveRequestProbe.requests.push({
              url,
              method,
              time: Math.round(performance.now())
            });
          }

          return window.__opBacklogsOriginalFetch(...args);
        };
      JS
    end

    def stop_backlogs_move_request_probe
      page.execute_script(<<~JS)
        if (window.__opBacklogsOriginalFetch) {
          window.fetch = window.__opBacklogsOriginalFetch;
        }
      JS
    end

    def backlogs_dnd_diagnostics
      diagnostics = page.evaluate_script(<<~JS)
        (() => {
          const dnd = window.__opBacklogsDndProbeState ?? null;
          const turbo = window.__opBacklogsTurboStreamState ?? null;

          if (dnd) {
            dnd.snapshots.push({
              label: 'on-timeout',
              draggingCount: document.querySelectorAll('[data-dragging]').length,
              honeyPotCount: document.querySelectorAll('[data-pdnd-honey-pot]').length,
              dropTargets: document.querySelectorAll('[data-drop-target-for-element]').length,
              dropPositions: Array
                .from(document.querySelectorAll('[data-drop-position]'))
                .map((element) => ({
                  itemId: element
                    .closest('[data-sortable-lists--item-id-value]')
                    ?.getAttribute('data-sortable-lists--item-id-value') ?? null,
                  position: element.getAttribute('data-drop-position')
                })),
              source: dnd.source,
              target: dnd.target,
              time: Math.round(performance.now())
            });
          }

          return { dnd, turbo };
        })()
      JS

      JSON.pretty_generate(diagnostics)
    end

    def clear_pragmatic_dnd_honey_pot
      page.execute_script(<<~JS)
        document
          .querySelectorAll('[data-pdnd-honey-pot]')
          .forEach((element) => element.remove());
      JS
    end

    def sprint_complete_modal_selector
      "##{::Backlogs::FinishSprintDialogComponent::DIALOG_ID}"
    end

    def backlog_bucket_destroy_modal_selector
      test_selector(Backlogs::BucketDestroyModalComponent::TEST_SELECTOR)
    end

    def open_controlled_menu(button)
      button.click
      page.find(:menu, id: button[:controls] || button["aria-controls"])
    end

    def open_move_submenu(menu)
      move_item = menu.find(:menuitem, text: "Move to position")
      move_item.click
      page.find(:menu, id: move_item["aria-controls"])
    end

    def dismiss_menu(menu_owner)
      overlay_id = "#{ActionView::RecordIdentifier.dom_target(menu_owner, :menu)}-overlay"
      selector = "##{overlay_id}"

      return unless page.has_css?(selector, visible: true, wait: 0)
      return if page.has_selector?(:modal, wait: 0)

      find(selector, wait: 0).click
    rescue Capybara::ElementNotFound, Selenium::WebDriver::Error::ElementNotInteractableError
      # Menu actions can close the menu or open a modal between the checks
      # above and the click; once the menu is gone or a modal owns focus,
      # dismissal is moot.
      raise unless page.has_selector?(:modal, wait: 0) ||
        page.has_no_css?(selector, visible: true, wait: 0)
    end

    def headed_section_titles(id_prefix:)
      page
        .all(:section, section_element: :section, heading_level: 4)
        .select { |section| section[:id].to_s.start_with?(id_prefix) }
        .map { |section| section.first(:heading, level: 4).text }
    end

    def sprint_names_in_order
      within_sprint_backlogs do
        headed_section_titles(id_prefix: "backlogs-sprint-component-")
      end
    end

    def bucket_names_in_order
      within_owner_backlogs do
        headed_section_titles(id_prefix: "backlogs-bucket-component-")
      end
    end
  end
end
