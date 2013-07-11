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

require File.expand_path('../../spec_helper', __FILE__)

describe PrincipalsController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  describe 'paginate_principals.json' do
    let(:query_params) { { "q"=>"lorem", "page_limit"=>"10", "page"=>"1" } }
    let(:result) { [FactoryGirl.build_stubbed(:user)] }
    let(:scope) { double('search_scope') }

    before do
      Principal.should_receive(:search_scope)
               .with(query_params["q"])
               .and_return(scope)

      scope.should_receive(:paginate)
           .with(:page => query_params["page"].to_i, :per_page => query_params["page_limit"].to_i)
           .and_return(result)
    end

    def fetch
      get 'paginate_principals',
          query_params,
          :format => 'json'
    end

    it_should_behave_like "a controller action with unrestricted access"
  end
end
