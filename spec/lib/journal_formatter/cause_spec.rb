#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe OpenProject::JournalFormatter::Cause do
  include ApplicationHelper
  include WorkPackagesHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  let(:work_package) { create(:work_package) }
  let(:instance) { described_class.new(build(:work_package_journal)) }
  let(:link) do
    link_to_work_package(work_package, all_link: true)
  end

  # we need to tell the url_helper that there is not controller to get url_options so that we can call link_to
  let(:controller) { nil }

  subject { instance.render("cause", [nil, cause], html:) }

  context 'when the change was caused by a change to the parent' do
    let(:cause) do
      {
        "type" => "work_package_parent_changed_times",
        "work_package_id" => work_package.id
      }
    end

    context 'when rendering HTML variant' do
      let(:html) { true }

      context 'when the user is able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
        end

        it do
          expect(subject).to eq "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
                                "#{I18n.t('journals.cause_descriptions.work_package_parent_changed_times', link:)}"
        end
      end

      context 'when the user is not able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
        end

        it do
          expect(subject).to eq "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
                                "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        end
      end
    end

    context 'when rendering raw variant' do
      let(:html) { false }

      context 'when the user is able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
        end

        let(:link) { "##{work_package.id}" }

        it do
          expect(subject).to eq "#{I18n.t('journals.caused_changes.dates_changed')} " \
                                "#{I18n.t('journals.cause_descriptions.work_package_parent_changed_times', link:)}"
        end
      end

      context 'when the user is not able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
        end

        it do
          expect(subject).to eq "#{I18n.t('journals.caused_changes.dates_changed')} " \
                                "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        end
      end
    end
  end

  context 'when the change was caused by a change to a predecessor' do
    let(:cause) do
      {
        "type" => "work_package_predecessor_changed_times",
        "work_package_id" => work_package.id
      }
    end

    context 'when rendering HTML variant' do
      let(:html) { true }

      context 'when the user is able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
        end

        it do
          expect(subject).to eq "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
                                "#{I18n.t('journals.cause_descriptions.work_package_predecessor_changed_times', link:)}"
        end
      end

      context 'when the user is not able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
        end

        it do
          expect(subject).to eq "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
                                "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        end
      end
    end

    context 'when rendering raw variant' do
      let(:html) { false }

      context 'when the user is able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
        end

        let(:link) { "##{work_package.id}" }

        it do
          expect(subject).to eq "#{I18n.t('journals.caused_changes.dates_changed')} " \
                                "#{I18n.t('journals.cause_descriptions.work_package_predecessor_changed_times', link:)}"
        end
      end

      context 'when the user is not able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
        end

        it do
          expect(subject).to eq "#{I18n.t('journals.caused_changes.dates_changed')} " \
                                "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        end
      end
    end
  end

  context 'when the change was caused by a change to a child' do
    let(:cause) do
      {
        "type" => "work_package_children_changed_times",
        "work_package_id" => work_package.id
      }
    end

    context 'when rendering HTML variant' do
      let(:html) { true }

      context 'when the user is able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
        end

        it do
          expect(subject).to eq "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
                                "#{I18n.t('journals.cause_descriptions.work_package_children_changed_times', link:)}"
        end
      end

      context 'when the user is not able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
        end

        it do
          expect(subject).to eq "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
                                "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        end
      end
    end

    context 'when rendering raw variant' do
      let(:html) { false }

      context 'when the user is able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
        end

        let(:link) { "##{work_package.id}" }

        it do
          expect(subject).to eq "#{I18n.t('journals.caused_changes.dates_changed')} " \
                                "#{I18n.t('journals.cause_descriptions.work_package_children_changed_times', link:)}"
        end
      end

      context 'when the user is not able to access the related work package' do
        before do
          allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
        end

        it do
          expect(subject).to eq "#{I18n.t('journals.caused_changes.dates_changed')} " \
                                "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        end
      end
    end
  end

  context 'when the change was caused by working day changes' do
    let(:cause) do
      {
        "type" => 'working_days_changed',
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

    context 'when rendering HTML variant' do
      let(:html) { true }

      it do
        changes = [
          I18n.t("journals.cause_descriptions.working_days_changed.days.non_working", day: WeekDay.find_by!(day: 2).name),
          I18n.t("journals.cause_descriptions.working_days_changed.days.working", day: WeekDay.find_by!(day: 6).name),
          I18n.t("journals.cause_descriptions.working_days_changed.dates.working", date: I18n.l(Date.new(2023, 1, 1))),
          I18n.t("journals.cause_descriptions.working_days_changed.dates.non_working", date: I18n.l(Date.new(2023, 12, 24)))
        ].join(", ")
        expect(subject).to eq "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
                              "#{I18n.t('journals.cause_descriptions.working_days_changed.changed', changes:)}"
      end
    end

    context 'when rendering raw variant' do
      let(:html) { false }

      it do
        changes = [
          I18n.t("journals.cause_descriptions.working_days_changed.days.non_working", day: WeekDay.find_by!(day: 2).name),
          I18n.t("journals.cause_descriptions.working_days_changed.days.working", day: WeekDay.find_by!(day: 6).name),
          I18n.t("journals.cause_descriptions.working_days_changed.dates.working", date: I18n.l(Date.new(2023, 1, 1))),
          I18n.t("journals.cause_descriptions.working_days_changed.dates.non_working", date: I18n.l(Date.new(2023, 12, 24)))
        ].join(", ")
        expect(subject).to eq "#{I18n.t('journals.caused_changes.dates_changed')} " \
                              "#{I18n.t('journals.cause_descriptions.working_days_changed.changed', changes:)}"
      end
    end
  end

  context 'when the change was caused by a system update' do
    let(:cause) do
      {
        "type" => 'system_update',
        "feature" => 'file_links_journal'
      }
    end

    context 'when rendering HTML variant' do
      let(:html) { true }

      it do
        expect(subject).to eq "<strong>#{I18n.t('journals.caused_changes.system_update')}</strong> " \
                              "#{I18n.t('journals.cause_descriptions.system_update.file_links_journal')}"
      end
    end

    context 'when rendering raw variant' do
      let(:html) { false }

      it do
        expect(subject).to eq "#{I18n.t('journals.caused_changes.system_update')} " \
                              "#{I18n.t('journals.cause_descriptions.system_update.file_links_journal')}"
      end
    end
  end
end
