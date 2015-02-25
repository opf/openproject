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

class OpenProject::PrincipalAllowanceEvaluator::Base
  def initialize(user)
    @user = user
  end

  def granted_for_global?(_candidate, _action, _options)
    false
  end

  def denied_for_global?(_candidate, _action, _options)
    false
  end

  def granted_for_project?(_candidate, _action, _project, _options = {})
    false
  end

  def denied_for_project?(_candidate, _action, _project, _options = {})
    false
  end

  def global_granting_candidates
    []
  end

  def project_granting_candidates(_project)
    []
  end

  def self.eager_load_for_project_authorization(project)
    nil
  end
end
