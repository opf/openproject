#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module AdminHelper
  def project_status_options_for_select(selected)
    options_for_select([[l(:label_all), ''],
                        [l(:status_active), 1]], selected)
  end
end
