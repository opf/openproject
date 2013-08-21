#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  let(:klass) { User }

  describe :registered_allowance_evaluators do
    it { klass.registered_allowance_evaluators.should include(OpenProject::GlobalRoles::PrincipalAllowanceEvaluator::Global) }
  end
end
