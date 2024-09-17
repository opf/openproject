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

RSpec.describe API::Utilities::PropertyNameConverter do
  describe "#from_ar_name" do
    let(:attribute_name) { :an_attribute }

    subject { described_class.from_ar_name(attribute_name) }

    it "stringifies attribute names" do
      expect(subject).to be_a(String)
    end

    it "camelizes attribute names" do
      expect(subject).to eql("anAttribute")
    end

    context "foreign keys" do
      let(:attribute_name) { :thing_id }

      it "eliminates the id suffix" do
        expect(subject).to eql("thing")
      end
    end

    context "custom fields" do
      let(:attribute_name) { :cf_1337 }

      it "converts short custom fields to their long form" do
        expect(subject).to eql("customField1337")
      end
    end

    # N.B. not re-iterating all existing known replacements here. Just using a single example
    # to verify that it is done at all
    context "special replacements" do
      let(:attribute_name) { :assigned_to }

      it "performs special replacements" do
        expect(subject).to eql("assignee")
      end

      context "foreign keys" do
        let(:attribute_name) { :assigned_to_id }

        it "sanitizes id-suffix before replacement lookup" do
          expect(subject).to eql("assignee")
        end
      end
    end
  end

  describe "#to_ar_name" do
    let(:attribute_name) { "anAttribute" }
    let(:context) { build_stubbed(:work_package) }

    subject { described_class.to_ar_name(attribute_name, context:) }

    it "snake_cases attribute names" do
      expect(subject).to eql("an_attribute")
    end

    context "foreign keys" do
      let(:attribute_name) { "status" }

      it "does not add an id suffix by default" do
        expect(subject).to eql("status")
      end

      context "requesting ids via refer_to_ids" do
        subject { described_class.to_ar_name(attribute_name, context:, refer_to_ids: true) }

        context "for keys referring to a belongs_to association" do
          let(:attribute_name) { "status" }

          it "adds an id suffix" do
            expect(subject).to eql("status_id")
          end
        end

        context "for keys referring to a has_many association" do
          let(:attribute_name) { "watcher" }

          it "adds an id suffix" do
            expect(subject).to eql("watcher_ids")
          end
        end

        context "for non-foreign keys" do
          let(:attribute_name) { "subject" }

          it "does not add an id suffix" do
            expect(subject).to eql("subject")
          end
        end

        context "does not append an id to pluarlized attributes" do
          let(:attribute_name) { "estimatedTime" }

          it "does not add an id suffix" do
            expect(subject).to eql("estimated_hours")
          end
        end
      end
    end

    context "custom fields" do
      let(:attribute_name) { "customField1337" }

      it "converts long custom fields to their short form" do
        expect(subject).to eql("cf_1337")
      end
    end

    context "special replacements" do
      let(:attribute_name) { "assignee" }

      it "performs special replacements" do
        expect(subject).to eql("assigned_to")
      end

      context "foreign keys" do
        let(:attribute_name) { "assignee" }

        subject { described_class.to_ar_name(attribute_name, context:, refer_to_ids: true) }

        it "correctly appends the id suffix" do
          expect(subject).to eql("assigned_to_id")
        end
      end

      context "inapropriate back-replacement" do
        # should not be translated back to updated_at, which is transformed for ar->api
        let(:attribute_name) { "updatedAt" }

        it "is not performed" do
          expect(subject).to eql("updated_at")
        end

        context "in an appropriate context" do
          let(:context) { build_stubbed(:version) }

          it "is performed" do
            expect(subject).to eql("updated_at")
          end
        end
      end

      context "inappropriate replacement as context does not respond to it with foreign key" do
        let(:attribute_name) { "type" }

        subject { described_class.to_ar_name(attribute_name, context:, refer_to_ids: true) }

        it "does not take the special replacement but appends the id suffix" do
          expect(subject).to eql("type_id")
        end
      end
    end
  end
end
