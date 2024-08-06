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

RSpec.describe ApplicationComponent, type: :component do
  describe ".options" do
    let(:component_class) do
      Class.new(described_class) do
        options title: "Hello World!", subtitle: "How are you today?"
        options enabled: true
        options :x, :y
      end
    end

    it "defines options with default values as constructor attributes" do
      component = component_class.new

      expect(component.title).to eq("Hello World!")
      expect(component.subtitle).to eq("How are you today?")
      expect(component.enabled).to be(true)
      expect(component.x).to be_nil
      expect(component.y).to be_nil
    end

    it "returns value used in constructor if present" do
      component = component_class.new(title: "My title", subtitle: nil, enabled: false, x: 13, y: 37)

      expect(component.title).to eq("My title")
      expect(component.subtitle).to be_nil
      expect(component.enabled).to be(false)
      expect(component.x).to eq(13)
      expect(component.y).to eq(37)
    end
  end
end
