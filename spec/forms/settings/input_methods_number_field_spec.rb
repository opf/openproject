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

require "rails_helper"

RSpec.describe Settings::InputMethods, "#number_field", :aggregate_failures, :settings_reset, type: :forms do
  include_context "with rendered inline settings form"
  include_context "with locale for testing"

  let(:translations) { { setting_ultimate_answer: "Ultimate answer" } }
  let(:name) { "ultimate_answer" }
  let(:allowed) { nil }
  let(:field_options) { {} }

  before do
    Settings::Definition.add(name, default: 42, format: :integer, allowed:)
  end

  subject(:rendered_form) do
    vc_render_inline_settings_form do |settings_form|
      settings_form.number_field(name: :ultimate_answer, **field_options)
    end

    page
  end

  it "renders a number field with the setting's value" do
    expect(rendered_form).to have_field "Ultimate answer", type: :number, with: "42" do |field|
      expect(field["min"]).to be_nil
      expect(field["max"]).to be_nil
    end
  end

  context "when the allowed values are a range" do
    let(:allowed) { 1...100 }

    it "limits the field to the range" do
      expect(rendered_form).to have_field "Ultimate answer", type: :number do |field|
        expect(field["min"]).to eq "1"
        expect(field["max"]).to eq "99"
      end
    end
  end

  context "when the allowed values are an endless range" do
    let(:allowed) { 0.. }

    it "only sets a minimum" do
      expect(rendered_form).to have_field "Ultimate answer", type: :number do |field|
        expect(field["min"]).to eq "0"
        expect(field["max"]).to be_nil
      end
    end
  end

  context "when min and max are given explicitly" do
    let(:allowed) { 1..100 }
    let(:field_options) { { min: 10, max: 20 } }

    it "prefers them over the range" do
      expect(rendered_form).to have_field "Ultimate answer", type: :number do |field|
        expect(field["min"]).to eq "10"
        expect(field["max"]).to eq "20"
      end
    end
  end
end
