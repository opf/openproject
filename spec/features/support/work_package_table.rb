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

shared_context 'work package table helpers' do
  def expect_work_packages_to_be_in_order(order)
    within_wp_table do
      preceeding_elements = order[0..-2]
      following_elements = order[1..-1]

      preceeding_elements.each_with_index do |wp_1, i|
        wp_2 = following_elements[i]
        expect(self).to have_selector(".wp-row-#{wp_1.id} + \
                                       .wp-row-#{wp_2.id}")
      end
    end
  end

  def within_wp_table(&block)
    within('.work-package-table--container', &block)
  end
end
