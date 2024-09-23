# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Acts::Journalized::JournableDiffer do
  describe ".changes" do
    context "when the objects are work packages" do
      let(:original) do
        build_stubbed(:work_package,
                      subject: "The original work package title",
                      description: "The description\n",
                      assigned_to_id: nil,
                      schedule_manually: false,
                      ignore_non_working_days: true,
                      estimated_hours: 1)
      end
      let(:changed) do
        build_stubbed(:work_package,
                      subject: "The changed work package title",
                      description: "The description\r\n",
                      priority: original.priority,
                      type: original.type,
                      project: original.project,
                      schedule_manually: nil,
                      ignore_non_working_days: false,
                      estimated_hours: nil)
      end

      it "returns the changes" do
        expect(described_class.changes(original, changed))
          .to eql("subject" => [original.subject, changed.subject],
                  "author_id" => [original.author_id, changed.author_id],
                  "status_id" => [original.status_id, changed.status_id],
                  "schedule_manually" => [false, nil],
                  "ignore_non_working_days" => [true, false],
                  "estimated_hours" => [1.0, nil])
      end
    end

    context "when the objects are WorkPackageJournal" do
      let(:original) do
        build_stubbed(:journal_work_package_journal,
                      subject: "The original work package title",
                      description: nil,
                      priority_id: 5,
                      type_id: 89,
                      project_id: 12,
                      status_id: 45,
                      schedule_manually: nil,
                      ignore_non_working_days: false,
                      estimated_hours: nil)
      end
      let(:changed) do
        build_stubbed(:journal_work_package_journal,
                      subject: "The changed work package title",
                      description: "",
                      priority_id: original.priority_id,
                      type_id: original.type_id,
                      project_id: original.project_id,
                      status_id: original.status_id + 12,
                      schedule_manually: false,
                      ignore_non_working_days: true,
                      estimated_hours: 1)
      end

      it "returns the changes" do
        # The description field changes from nil to '', but we want filter those transitions out,
        # hence the expected hash does not contain the description related change.
        expect(described_class.changes(original, changed))
          .to eql("subject" => [original.subject, changed.subject],
                  "status_id" => [original.status_id, changed.status_id],
                  "schedule_manually" => [nil, false],
                  "ignore_non_working_days" => [false, true],
                  "estimated_hours" => [nil, 1.0])
      end
    end
  end

  describe ".association_changes" do
    context "when the objects are work packages" do
      let(:original) do
        build(:work_package,
              custom_values: [
                build_stubbed(:work_package_custom_value, custom_field_id: 1, value: 1),
                build_stubbed(:work_package_custom_value, custom_field_id: 2, value: nil),
                build_stubbed(:work_package_custom_value, custom_field_id: 3, value: "")
              ])
      end

      let(:changed) do
        build(:work_package,
              custom_values: [
                build_stubbed(:work_package_custom_value, custom_field_id: 1, value: ""),
                build_stubbed(:work_package_custom_value, custom_field_id: 2, value: ""),
                build_stubbed(:work_package_custom_value, custom_field_id: 3, value: 2)
              ])
      end

      it "returns the changes" do
        params = [original, changed, "custom_values", "custom_field", :custom_field_id, :value]
        expect(described_class.association_changes(*params))
          .to eql(
            "custom_field_1" => ["1", ""],
            "custom_field_3" => ["", "2"]
          )
      end
    end

    context "with a default custom value" do
      let(:original) do
        build(:work_package,
              custom_values: [
                build_stubbed(:work_package_custom_value, custom_field_id: nil, value: nil),
                build_stubbed(:work_package_custom_value, custom_field_id: nil, value: ""),
                build_stubbed(:work_package_custom_value, custom_field_id: 2, value: 1)
              ])
      end

      let(:changed) do
        build(:work_package,
              custom_values: [
                build_stubbed(:work_package_custom_value, custom_field_id: 1, value: "t"),
                build_stubbed(:work_package_custom_value, custom_field_id: 2, value: 2)
              ])
      end

      it "returns the changes" do
        params = [original, changed, "custom_values", "custom_field", :custom_field_id, :value]
        expect(described_class.association_changes(*params))
          .to eql("custom_field_1" => [nil, "t"],
                  "custom_field_2" => ["1", "2"])
      end
    end
  end
end
