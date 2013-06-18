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
    helper.stub!(:params).and_return( { :controller => 'issues', :action => 'index' }.with_indifferent_access )

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

    it "should have a next_page reference" do
      pagination.should have_selector(".next_page")
    end

    it "should have a previous_page reference" do
      pagination.should have_selector(".previous_page")
    end

    it "should have links to every page except the current one" do
      (1..(total_entries / per_page)).each do |i|
        next if i == current_page

        pagination.should have_selector("a[href='#{issues_path(:page => i)}']", :text => Regexp.new("^#{i}$"))
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

    it "should show the available pre page options" do
      ar = Setting.per_page_options

      Setting.per_page_options = "#{per_page},#{per_page * 10}"

      pagination.should have_selector("span.per_page_options")

      pagination.should have_selector(".per_page_options span.current", :text => per_page)
      pagination.should have_selector(".per_page_options a[href='#{issues_path(:per_page => Setting.per_page_options_array.last)}']")

      Setting.per_page_options = ar
    end

    describe "WHEN the first page is the current" do
      let(:current_page) { 1 }

      it "should deactivate the previous page link" do
        pagination.should have_selector(".previous_page.disabled")
      end

    end

    describe "WHEN the last page is the current" do
      let(:current_page) { total_entries/per_page + 1 }

      it "should deactivate the next page link" do
        pagination.should have_selector(".next_page.disabled")
      end

    end

    describe "WHEN the paginated object is empty" do
      let(:total_entries) { 0 }

      it "should be empty" do
        pagination.should have_selector(".pagination", :text => /^$/)
      end
    end
  end
end
