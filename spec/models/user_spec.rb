#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe User, :type => :model do
  let(:klass) { User }

  describe :registered_allowance_evaluators do
    it { expect(klass.registered_allowance_evaluators).to include(OpenProject::GlobalRoles::PrincipalAllowanceEvaluator::Global) }
  end
end
