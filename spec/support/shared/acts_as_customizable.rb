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

RSpec.shared_examples_for "acts_as_customizable included" do
  describe "#custom_field_changes" do
    context "when no custom field value exists" do
      before do
        model_instance.custom_values.destroy_all
      end

      it "returns no changes" do
        expect(model_instance.custom_field_changes).to be_empty
      end

      context "when a field value is set" do
        before do
          model_instance.custom_values.destroy_all
        end

        it "returns the field changes" do
          model_instance.custom_field_values = { custom_field.id => "test" }
          expect(model_instance.custom_field_changes)
            .to eq({ custom_field.attribute_name => [nil, "test"] })
        end
      end
    end

    context "when a field value is changed from nil" do
      it "returns the field changes" do
        model_instance.custom_field_values = { custom_field.id => "test" }
        expect(model_instance.custom_field_changes)
          .to eq({ custom_field.attribute_name => [nil, "test"] })
      end
    end

    context "when a field value is changed from a string" do
      before do
        model_instance.custom_field_values = { custom_field.id => "test" }
        model_instance.save
      end

      it "returns the field changes" do
        model_instance.custom_field_values = { custom_field.id => "test2" }
        expect(model_instance.custom_field_changes)
          .to eq({ custom_field.attribute_name => ["test", "test2"] })
      end
    end

    context "when a field is set to the same value (unchanged)" do
      before do
        model_instance.custom_field_values = { custom_field.id => "test" }
        model_instance.save
      end

      it "returns no changes" do
        model_instance.custom_field_values = { custom_field.id => "test" }
        expect(model_instance.custom_field_changes).to be_empty
      end
    end

    context "when a field value is changed to nil" do
      before do
        model_instance.custom_field_values = { custom_field.id => "test" }
        model_instance.save
      end

      it "returns the field changes" do
        model_instance.custom_field_values = { custom_field.id => nil }
        expect(model_instance.custom_field_changes)
          .to eq({ custom_field.attribute_name => ["test", nil] })
      end
    end
  end
end
