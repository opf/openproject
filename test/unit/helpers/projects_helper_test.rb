# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../../test_helper'

class ProjectsHelperTest < HelperTestCase
  include ProjectsHelper
  include ActionView::Helpers::TextHelper
  fixtures :projects, :trackers, :issue_statuses, :issues, :enumerations, :users, :issue_categories

  def setup
    super
  end
  
  if Object.const_defined?(:Magick)
    def test_gantt_image
      assert gantt_image(Issue.find(:all, :conditions => "start_date IS NOT NULL AND due_date IS NOT NULL"), Date.today, 6, 2)
    end

    def test_gantt_image_with_days
      assert gantt_image(Issue.find(:all, :conditions => "start_date IS NOT NULL AND due_date IS NOT NULL"), Date.today, 3, 4)
    end
  else
    puts "RMagick not installed. Skipping tests !!!"
    def test_fake; assert true end
  end
end
