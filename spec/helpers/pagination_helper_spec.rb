#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

require 'spec_helper'

describe PaginationHelper do

  let(:paginator) do
    # creating a mock pagination object
    # this one is then identical (from the interface) to a active record
    paginator = WillPaginate::Collection.create(current_page, per_page) do |pager|
      result = pager.per_page.times.map{|i| i}

      pager.replace(result)

      unless pager.total_entries
        pager.total_entries = total_entries
      end
    end

    # this is required in order to be able to produce a valid url
    helper.stub(:params).and_return( { :controller => 'work_packages', :action => 'index' }.with_indifferent_access )

    paginator
  end

  describe :pagination_links_full do
    let(:per_page) { 10 }
    let(:total_entries) { 55 }
    let(:offset) { 1 }
    let(:current_page) { 1 }
    let(:pagination) { helper.pagination_links_full(paginator) }

    it "should be inside a 'pagination' p" do
      pagination.should have_selector("p.pagination")
    end

    it "should not be inside a 'pagination' p if not desired" do
      helper.pagination_links_full(paginator, :container => false).should_not have_selector("p.pagination")
    end

    it "should have a next_page reference" do
      pagination.should have_selector(".next_page")
    end

    it "should have a previous_page reference" do
      pagination.should have_selector(".previous_page")
    end

    it "should have links to every page except the current one" do
      (1..(total_entries / per_page)).each do |i|
        next if i == current_page

        pagination.should have_selector("a[href='#{work_packages_path(:page => i)}']", :text => Regexp.new("^#{i}$"))
      end
    end

    it "should not have a link to the current page" do
      pagination.should_not have_selector("a", :text => Regexp.new("^#{current_page}$"))
    end

    it "should have an element for the curren page" do
      pagination.should have_selector("em.current", :text => Regexp.new("^#{current_page}$"))
    end

    it "should show the range of the entries displayed" do
      pagination.should have_selector("span.range",
                                      :text => "(#{(current_page * per_page) - per_page + 1} - #{current_page * per_page}/#{total_entries})")
    end

    it "should have different urls if the params are specified as options" do
      params = { :controller => 'work_packages', :action => 'index' }

      pagination = helper.pagination_links_full(paginator, { :params => params })

      (1..(total_entries / per_page)).each do |i|
        next if i == current_page

        pagination.should have_selector("a[href='#{work_packages_path({:page => i}.merge(params))}']", :text => Regexp.new("^#{i}$"))
      end
    end

    it "should show the available pre page options" do
      ar = Setting.per_page_options

      Setting.per_page_options = "#{per_page},#{per_page * 10}"

      pagination.should have_selector("span.per_page_options")

      pagination.should have_selector(".per_page_options span.current", :text => per_page)
      pagination.should have_selector(".per_page_options a[href='#{work_packages_path(:page => current_page, :per_page => Setting.per_page_options_array.last)}']")

      Setting.per_page_options = ar
    end

    describe "WHEN the first page is the current" do
      let(:current_page) { 1 }

      it "should deactivate the previous page link" do
        pagination.should have_selector(".previous_page.disabled")
      end

      it "should have a link to the next page" do
        pagination.should have_selector("a.next_page[href='#{work_packages_path({:page => current_page + 1})}']")
      end
    end

    describe "WHEN the last page is the current" do
      let(:current_page) { total_entries/per_page + 1 }

      it "should deactivate the next page link" do
        pagination.should have_selector(".next_page.disabled")
      end

      it "should have a link to the previous page" do
        pagination.should have_selector("a.previous_page[href='#{work_packages_path({:page => current_page - 1})}']")
      end
    end

    describe "WHEN the paginated object is empty" do
      let(:total_entries) { 0 }

      it "should be empty" do
        pagination.should have_selector(".pagination", :text => /\A\z/)
      end
    end
  end

  describe :page_param do
    it "should return page if provided and sensible" do
      page = 2

      page_param( { :page => page } ).should == page
    end

    it "should return default page 1 if page provided but useless" do
      page = 0

      page_param( { :page => page } ).should == 1
    end

    it "should calculate page from offset and limit if page is not provided" do
      # need to change settings as only multiples of per_page
      # are allowed for limit
      with_settings :per_page_options => '5,10,15' do
        offset = 55
        limit = 10

        page_param( { :offset => offset, :limit => limit } ).should == 6
      end
    end

    it "should ignore offset and limit if page is provided" do
      offset = 55
      limit = 10
      page = 7

      page_param( { :offset => offset, :limit => limit, :page => page } ).should == page
    end

    it "should not break if limit is bogus (also faulty settings)" do
      with_settings :per_page_options => '-1,2,3' do
        offset = 55
        limit = "lorem"

        page_param( { :offset => offset, :limit => limit } ).should == 28
      end
    end

    it "should return 1 if nothing is provided" do
      page_param( {} ).should == 1
    end
  end

  describe :per_page_param do
    it "should return per_page if provided and one of the values stored in the settings" do
      with_settings :per_page_options => '1,2,3' do
        per_page = 2

        per_page_param( { :per_page => per_page } ).should == per_page
      end
    end

    it "should return per_page if provided and store it in the session" do
      with_settings :per_page_options => '1,2,3' do
        session[:per_page] = 3
        per_page = 2

        per_page_param( { :per_page => per_page } ).should == per_page
        session[:per_page].should == 2
      end
    end

    it "should take the smallest value stored in the settings if provided per_page param is not one of the configured" do
      with_settings :per_page_options => '1,2,3' do
        per_page = 4

        per_page_param( { :per_page => per_page } ).should == 1
      end
    end

    it "preferes the value stored in the session if it is valid according to the settings" do
      with_settings :per_page_options => '1,2,3' do
        session[:per_page] = 2

        per_page_param( { :per_page => 3 } ).should == session[:per_page]
      end
    end

    it "ignores the value stored in the session if it is not valid according to the settings" do
      with_settings :per_page_options => '1,2,3' do
        session[:per_page] = 4

        per_page_param( { :per_page => 3 } ).should == 3
      end
    end

    it "uses limit synonomously to per_page" do
      with_settings :per_page_options => '1,2,3' do
        limit = 2

        per_page_param( { :limit => limit } ).should == limit
      end
    end

    it "preferes per_page over limit" do
      with_settings :per_page_options => '1,2,3' do
        limit = 2
        per_page = 3

        per_page_param( { :limit => limit, :per_page => per_page } ).should == per_page
      end
    end

    it "stores the value in the session" do
      with_settings :per_page_options => '1,2,3' do
        limit = 2

        per_page_param( { :limit => limit } )

        session[:per_page].should == limit
      end
    end
  end
end
