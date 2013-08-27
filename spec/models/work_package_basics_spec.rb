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

describe WorkPackage do

  describe "validations" do

    # validations
    [:subject, :priority, :project, :type, :author, :status].each do |field|
      it{ should validate_presence_of field}
    end

    it { should ensure_length_of(:subject).is_at_most 255 }
    it { should ensure_inclusion_of(:done_ratio).in_range 0..100 }
    it { should validate_numericality_of :estimated_hours}

    it "validate, that start-date is before end-date" do
      wp = FactoryGirl.build(:work_package, start_date: 1.day.from_now, due_date: Time.now)
      expect(wp).to have(1).errors_on(:due_date)
    end

    it "validate, that correct formats are properly validated" do
      wp = FactoryGirl.build(:work_package, start_date: "01/01/13", due_date: "31/01/13")
      puts wp.valid?
      puts wp.errors.full_messages
      expect(wp).to have(0).errors_on(:start_date)
    end
  end




end