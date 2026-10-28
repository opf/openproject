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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

Rails.root.glob("lookbook/previews/**/*_preview.rb").each { |f| require f.to_s }

# To mark a component preview as pending, add the name and a reason here, using the format:
# "OpPrimer::StatusButtonComponentPreview" => "Needs design change",
# To mark only a specific preview instead of all previews for that component, add the name separated with a `#`
# "OpPrimer::StatusButtonComponentPreview#playground" => "Needs design change",
AXE_KNOWN_VIOLATIONS = {
  "OpPrimer::StatusButtonComponentPreview" => "Needs design change"
}.freeze

RSpec.describe "Lookbook previews accessibility", :component_preview, :js, :selenium do
  ViewComponent::Preview.all.each do |preview|
    describe preview.name do
      preview.examples.each do |example|
        it "#{example} has no WCAG violations in its default state" do
          key = [preview.name, "#{preview.name}##{example}"]

          if (reason = AXE_KNOWN_VIOLATIONS.values_at(*key).compact.first)
            pending reason
          end

          visit_preview(example.to_sym, from: preview)

          expect(page).to be_axe_clean.within(".viewcomponent-preview--content")
        end
      end
    end
  end
end
