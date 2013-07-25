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

module OpenProject
  describe I18n do
    include Redmine::I18n

    let(:format) { '%d/%m/%Y' }

    after do
      Time.zone = nil
    end

    describe 'with user time zone' do
      before { User.current.stub(:time_zone).and_return(ActiveSupport::TimeZone['Athens'])}
      it 'returns a date in the user timezone for a utc timestamp' do
        Time.zone = 'UTC'
        time = Time.zone.local(2013, 06, 30, 23, 59)
        expect(format_time_as_date(time,format)).to eq '01/07/2013'
      end

      it 'returns a date in the user timezone for a non-utc timestamp' do
        Time.zone = 'Berlin'
        time = Time.zone.local(2013, 06, 30, 23, 59)
        expect(format_time_as_date(time,format)).to eq '01/07/2013'
      end
    end

    describe 'without user time zone' do
      before { User.current.stub(:time_zone).and_return(nil)}

      it 'returns a date in the local system timezone for a utc timestamp' do
        Time.zone = 'UTC'
        time = Time.zone.local(2013, 06, 30, 23, 59)
        time.stub(:localtime).and_return(ActiveSupport::TimeZone['Athens'].local(2013, 07, 01, 01, 59))
        expect(format_time_as_date(time,format)).to eq '01/07/2013'
      end

      it 'returns a date in the original timezone for a non-utc timestamp' do
        Time.zone = 'Berlin'
        time = Time.zone.local(2013, 06, 30, 23, 59)
        expect(format_time_as_date(time,format)).to eq '30/06/2013'
      end
    end
  end
end
