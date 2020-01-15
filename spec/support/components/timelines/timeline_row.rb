#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Components
  module Timelines
    class TimelineRow
      include Capybara::DSL
      include RSpec::Matchers

      attr_reader :container

      def initialize(container)
        @container = container
      end

      def hover!
        @container.find('.timeline-element').hover
      end

      def expect_hovered_labels(left:, right:)
        hover!

        unless left.nil?
          expect(container).to have_selector(".labelHoverLeft.not-empty", text: left)
        end
        unless right.nil?
          expect(container).to have_selector(".labelHoverRight.not-empty", text: right)
        end

        expect(container).to have_selector(".labelLeft", visible: false)
        expect(container).to have_selector(".labelRight", visible: false)
        expect(container).to have_selector(".labelFarRight", visible: false)
      end

      def expect_labels(left:, right:, farRight:)
        {
          labelLeft: left,
          labelRight: right,
          labelFarRight: farRight
        }.each do |className, text|
          if text.nil?
            expect(container).to have_selector(".#{className}", visible: :all)
            expect(container).to have_no_selector(".#{className}.not-empty", wait: 0)
          else
            expect(container).to have_selector(".#{className}.not-empty", text: text)
          end
        end
      end
    end
  end
end
