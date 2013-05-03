require 'spec_helper'

describe HourlyRatesController do
  describe "routing" do
    it { get('/projects/blubs/hourly_rates/5').should route_to(:controller => 'hourly_rates',
                                                               :action => 'show',
                                                               :project_id => 'blubs',
                                                               :id => '5') }

    it { get('/projects/blubs/hourly_rates/5/edit').should route_to(:controller => 'hourly_rates',
                                                                    :action => 'edit',
                                                                    :project_id => 'blubs',
                                                                    :id => '5') }

    it { get('/hourly_rates/5/edit').should route_to(:controller => 'hourly_rates',
                                                     :action => 'edit',
                                                     :id => '5') }

    it { put('/projects/blubs/hourly_rates/5').should route_to(:controller => 'hourly_rates',
                                                               :action => 'update',
                                                               :project_id => 'blubs',
                                                               :id => '5') }

    it { post('/projects/blubs/hourly_rates/5/set_rate').should route_to(:controller => 'hourly_rates',
                                                                         :action => 'set_rate',
                                                                         :project_id => 'blubs',
                                                                         :id => '5') }
  end
end
