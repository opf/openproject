#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::RspecCleanup
  def self.cleanup
    # Cleanup after specs changing locale explicitly or
    # by calling code in the app setting changing the locale.
    I18n.locale = :en

    # Set the class instance variable @current_user to nil
    # to avoid having users from one spec present in the next
    ::User.instance_variable_set(:@current_user, nil)
  end
end

OpenProject::Configuration['attachments_storage_path'] = 'tmp/files'

RSpec.configure do |config|
  config.after(:each) do
    OpenProject::RspecCleanup.cleanup
  end

  config.after(:suite) do
    [User, Project, WorkPackage].each do |cls|
      if cls.count > 0
        raise "your specs leave a #{cls} in the DB\ndid you use before(:all) instead of before or forget to kill the instances in a after(:all)?"
      end
    end
  end
end
