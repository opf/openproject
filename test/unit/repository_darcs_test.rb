#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class RepositoryDarcsTest < ActiveSupport::TestCase
  fixtures :projects

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/darcs_repository'

  def setup
    @project = Project.find(3)
    @repository = Repository::Darcs.create(
                      :project => @project, :url => REPOSITORY_PATH,
                      :log_encoding => 'UTF-8')
    assert @repository
  end

  if File.directory?(REPOSITORY_PATH)
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload

      assert_equal 6, @repository.changesets.count
      assert_equal 13, @repository.changes.count
      assert_equal "Initial commit.", @repository.changesets.find_by_revision('1').comments
    end

    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove changesets with revision > 3
      @repository.changesets.find(:all).each {|c| c.destroy if c.revision.to_i > 3}
      @repository.reload
      assert_equal 3, @repository.changesets.count

      @repository.fetch_changesets
      assert_equal 6, @repository.changesets.count
    end

    def test_deleted_files_should_not_be_listed
      @repository.fetch_changesets
      @repository.reload
      entries = @repository.entries('sources')
      assert entries.detect {|e| e.name == 'watchers_controller.rb'}
      assert_nil entries.detect {|e| e.name == 'welcome_controller.rb'}
    end

    def test_cat
      if @repository.scm.supports_cat?
        @repository.fetch_changesets
        cat = @repository.cat("sources/welcome_controller.rb", 2)
        assert_not_nil cat
        assert cat.include?('class WelcomeController < ApplicationController')
      end
    end
  else
    puts "Darcs test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
