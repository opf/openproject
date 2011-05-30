#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module AdminHelper
  def project_status_options_for_select(selected)
    options_for_select([[l(:label_all), ''],
                        [l(:status_active), 1]], selected)
  end
end
