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

RSpec.describe OpenProject::JournalFormatter::Cause do
  include ApplicationHelper
  include WorkPackagesHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  shared_let(:work_package) { create(:work_package) }
  let(:instance) { described_class.new(build(:work_package_journal)) }
  let(:work_package_html_link) do
    link_to_work_package(work_package, all_link: true)
  end
  let(:work_package_raw_link) { "##{work_package.id}" }

  # we need to tell the url_helper that there is not controller to get url_options so that we can call link_to
  let(:controller) { nil }

  def render(cause, html:)
    if Journal::VALID_CAUSE_TYPES.exclude?(cause["type"])
      raise "#{cause['type'].inspect} is not a valid cause type from Journal::VALID_CAUSE_TYPES. " \
            "Please use one of #{Journal::VALID_CAUSE_TYPES}"
    end

    instance.render("cause", [nil, cause], html:)
  end

  RSpec::Matchers.define :render_html_variant do |expected|
    match do |cause|
      @cause = cause
      @actual = render(cause, html: true)
      values_match? expected, @actual
    end

    description do
      "render HTML variant with #{surface_descriptions_in(expected).inspect}"
    end

    failure_message do |actual|
      "expected #{@cause} to render HTML variant as expected\n  " \
        "expected: #{surface_descriptions_in(expected).inspect}\n  " \
        "actual:   #{actual.inspect}"
    end
  end

  RSpec::Matchers.define :render_raw_variant do |expected|
    match do |cause|
      @cause = cause
      @actual = render(cause, html: false)
      values_match? expected, @actual
    end

    description do
      "render raw text variant with #{surface_descriptions_in(expected).inspect}"
    end

    failure_message do |actual|
      "expected #{@cause} to render raw text variant as expected\n  " \
        "expected: #{surface_descriptions_in(expected).inspect}\n  " \
        "actual:   #{actual.inspect}"
    end
  end

  shared_examples "XSS-proof rendering of status name" do
    before do
      cause["status_name"] = "<script>alert('xss')</script>"
    end

    it "escapes the status name when rendering HTML" do
      expect(cause).to render_html_variant(a_string_including("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"))
    end

    it "does not escape the status name when rendering raw text" do
      expect(cause).to render_raw_variant(a_string_including("<script>alert('xss')</script>"))
    end
  end

  context "when the change was caused by a change to the parent" do
    subject(:cause) do
      {
        "type" => "work_package_parent_changed_times",
        "work_package_id" => work_package.id
      }
    end

    context "when the user is able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
      end

      it do
        link = work_package_html_link
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.work_package_parent_changed_times', link:)}"
        )
      end

      it do
        link = work_package_raw_link
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.work_package_parent_changed_times', link:)}"
        )
      end
    end

    context "when the user is not able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
      end

      it do
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end

      it do
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end
    end
  end

  context "when the change was caused by a change to a predecessor" do
    subject(:cause) do
      {
        "type" => "work_package_predecessor_changed_times",
        "work_package_id" => work_package.id
      }
    end

    context "when the user is able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
      end

      it do
        link = work_package_html_link
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.work_package_predecessor_changed_times', link:)}"
        )
      end

      it do
        link = work_package_raw_link
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.work_package_predecessor_changed_times', link:)}"
        )
      end
    end

    context "when the user is not able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
      end

      it do
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end

      it do
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end
    end
  end

  context "when the change was caused by a change to a child" do
    subject(:cause) do
      {
        "type" => "work_package_children_changed_times",
        "work_package_id" => work_package.id
      }
    end

    context "when the user is able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
      end

      it do
        link = work_package_html_link
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.work_package_children_changed_times', link:)}"
        )
      end

      it do
        link = work_package_raw_link
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.work_package_children_changed_times', link:)}"
        )
      end
    end

    context "when the user is not able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
      end

      it do
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end

      it do
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end
    end
  end

  context "when the change was caused by working day changes" do
    subject(:cause) do
      {
        "type" => "working_days_changed",
        "changed_days" => {
          "working_days" => {
            "2" => false,
            "6" => true

          },
          "non_working_days" => {
            "2023-01-01" => true,
            "2023-12-24" => false
          }
        }
      }
    end

    it do
      changes = [
        I18n.t("journals.cause_descriptions.working_days_changed.days.non_working", day: WeekDay.find_by!(day: 2).name),
        I18n.t("journals.cause_descriptions.working_days_changed.days.working", day: WeekDay.find_by!(day: 6).name),
        I18n.t("journals.cause_descriptions.working_days_changed.dates.working", date: I18n.l(Date.new(2023, 1, 1))),
        I18n.t("journals.cause_descriptions.working_days_changed.dates.non_working", date: I18n.l(Date.new(2023, 12, 24)))
      ].join(", ")
      expect(cause).to render_html_variant(
        "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
        "#{I18n.t('journals.cause_descriptions.working_days_changed.changed', changes:)}"
      )
    end

    it do
      changes = [
        I18n.t("journals.cause_descriptions.working_days_changed.days.non_working", day: WeekDay.find_by!(day: 2).name),
        I18n.t("journals.cause_descriptions.working_days_changed.days.working", day: WeekDay.find_by!(day: 6).name),
        I18n.t("journals.cause_descriptions.working_days_changed.dates.working", date: I18n.l(Date.new(2023, 1, 1))),
        I18n.t("journals.cause_descriptions.working_days_changed.dates.non_working", date: I18n.l(Date.new(2023, 12, 24)))
      ].join(", ")
      expect(cause).to render_raw_variant(
        "#{I18n.t('journals.caused_changes.dates_changed')} " \
        "#{I18n.t('journals.cause_descriptions.working_days_changed.changed', changes:)}"
      )
    end
  end

  context "when a change of status % complete is the cause" do
    shared_let(:status) { create(:status, name: "In progress", default_done_ratio: 40) }
    subject(:cause) do
      {
        "type" => "status_changed",
        "status_name" => status.name,
        "status_id" => status.id,
        "status_changes" => { "default_done_ratio" => [20, 40] }
      }
    end

    it do
      expect(cause).to render_html_variant("<strong>Status &#39;In progress&#39;</strong> " \
                                           "% complete changed from 20% to 40%")
    end

    it do
      expect(cause).to render_raw_variant("Status 'In progress' % complete changed from 20% to 40%")
    end

    it_behaves_like "XSS-proof rendering of status name"
  end

  context "when a status being excluded from totals is the cause" do
    shared_let(:status) { create(:status, name: "Rejected") }
    subject(:cause) do
      {
        "type" => "status_changed",
        "status_name" => status.name,
        "status_id" => status.id,
        "status_changes" => { "excluded_from_totals" => [false, true] }
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>Status &#39;Rejected&#39;</strong> now excluded from hierarchy totals"
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "Status 'Rejected' now excluded from hierarchy totals"
      )
    end

    it_behaves_like "XSS-proof rendering of status name"
  end

  context "when a status being no longer excluded from totals is the cause" do
    shared_let(:status) { create(:status, name: "Rejected") }
    subject(:cause) do
      {
        "type" => "status_changed",
        "status_name" => status.name,
        "status_id" => status.id,
        "status_changes" => { "excluded_from_totals" => [true, false] }
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>Status &#39;Rejected&#39;</strong> now included in hierarchy totals"
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "Status 'Rejected' now included in hierarchy totals"
      )
    end

    it_behaves_like "XSS-proof rendering of status name"
  end

  context "when a change of progress calculation mode to status-based is the cause" do
    subject(:cause) do
      {
        "type" => "progress_mode_changed_to_status_based"
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>Progress calculation updated</strong> " \
        "Progress calculation mode set to status-based"
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "Progress calculation updated " \
        "Progress calculation mode set to status-based"
      )
    end
  end

  context "when both a change of status % complete and excluded from totals is the cause" do
    shared_let(:status) { create(:status, name: "In progress", default_done_ratio: 40) }
    subject(:cause) do
      {
        "type" => "status_changed",
        "status_name" => status.name,
        "status_id" => status.id,
        "status_changes" => { "default_done_ratio" => [20, 40],
                              "excluded_from_totals" => [false, true] }
      }
    end

    it do
      expect(cause).to render_html_variant("<strong>Status &#39;In progress&#39;</strong> " \
                                           "% complete changed from 20% to 40% and now excluded from hierarchy totals")
    end

    it do
      expect(cause).to render_raw_variant("Status 'In progress' " \
                                          "% complete changed from 20% to 40% and now excluded from hierarchy totals")
    end

    it_behaves_like "XSS-proof rendering of status name"
  end

  context "when cause is a system update: change of progress calculation mode from disabled to work-based" do
    subject(:cause) do
      {
        "type" => "system_update",
        "feature" => "progress_calculation_adjusted_from_disabled_mode"
      }
    end

    it do
      href = OpenProject::Static::Links.links[:blog_article_progress_changes][:href]
      expect(cause).to render_html_variant(
        "<strong>OpenProject system update:</strong> Progress calculation automatically " \
        "<a href=\"#{href}\" target=\"_blank\">set to work-based mode and adjusted with version update</a>."
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "OpenProject system update: Progress calculation automatically " \
        "set to work-based mode and adjusted with version update."
      )
    end
  end

  context "when cause is a system update: progress calculation adjusted" do
    subject(:cause) do
      {
        "type" => "system_update",
        "feature" => "progress_calculation_adjusted"
      }
    end

    it do
      href = OpenProject::Static::Links.links[:blog_article_progress_changes][:href]
      expect(cause).to render_html_variant(
        "<strong>OpenProject system update:</strong> Progress calculation automatically " \
        "<a href=\"#{href}\" target=\"_blank\">adjusted with version update</a>."
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "OpenProject system update: Progress calculation automatically adjusted with version update."
      )
    end

    context "with previous feature key 'progress_calculation_changed'" do
      before do
        cause["feature"] = "progress_calculation_changed"
      end

      it "is rendered like 'progress_calculation_adjusted'" do
        expect(cause).to render_raw_variant(
          "OpenProject system update: Progress calculation automatically adjusted with version update."
        )
      end
    end
  end

  context "when cause is a system update: totals removed from childless work packages" do
    subject(:cause) do
      {
        "type" => "system_update",
        "feature" => "totals_removed_from_childless_work_packages"
      }
    end

    it do
      href = OpenProject::Static::Links.links[:release_notes_14_0_1][:href]
      expect(cause).to render_html_variant(
        "<strong>OpenProject system update:</strong> Work and progress totals " \
        "automatically removed for non-parent work packages with " \
        "<a href=\"#{href}\" target=\"_blank\">version update</a>. " \
        "This is a maintenance task and can be safely ignored."
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "OpenProject system update: Work and progress totals " \
        "automatically removed for non-parent work packages with version update. " \
        "This is a maintenance task and can be safely ignored."
      )
    end
  end

  context "when the change was caused by a system update" do
    subject(:cause) do
      {
        "type" => "system_update",
        "feature" => "file_links_journal"
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>#{I18n.t('journals.caused_changes.system_update')}</strong> " \
        "#{I18n.t('journals.cause_descriptions.system_update.file_links_journal')}"
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "#{I18n.t('journals.caused_changes.system_update')} " \
        "#{I18n.t('journals.cause_descriptions.system_update.file_links_journal')}"
      )
    end
  end
end
