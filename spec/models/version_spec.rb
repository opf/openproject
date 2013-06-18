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

require 'spec_helper'

describe Version do

  subject(:version){ FactoryGirl.build(:version, name: "Test Version") }

  it { should be_valid }

  it "rejects a due date that is smaller than the start date" do
    version.start_date = '2013-05-01'
    version.effective_date = '2012-01-01'

    expect(version).not_to be_valid
    expect(version.errors).to have(1).error_on(:effective_date)
  end
end
