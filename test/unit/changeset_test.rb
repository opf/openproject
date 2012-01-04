#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class ChangesetTest < ActiveSupport::TestCase
  fixtures :projects, :repositories, :issues, :issue_statuses,
           :changesets, :changes, :issue_categories, :enumerations,
           :custom_fields, :custom_values, :users, :members, :member_roles, :trackers

  def setup
  end

  def test_ref_keywords_any
    ActionMailer::Base.deliveries.clear
    Setting.commit_fix_status_id = IssueStatus.find(:first, :conditions => ["is_closed = ?", true]).id
    Setting.commit_fix_done_ratio = '90'
    Setting.commit_ref_keywords = '*'
    Setting.commit_fix_keywords = 'fixes , closes'

    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => 'New commit (#2). Fixes #1')
    c.scan_comment_for_issue_ids

    assert_equal [1, 2], c.issue_ids.sort
    fixed = Issue.find(1)
    assert fixed.closed?
    assert_equal 90, fixed.done_ratio
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  def test_ref_keywords
    Setting.commit_ref_keywords = 'refs'
    Setting.commit_fix_keywords = ''

    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => 'Ignores #2. Refs #1')
    c.scan_comment_for_issue_ids

    assert_equal [1], c.issue_ids.sort
  end

  def test_ref_keywords_any_only
    Setting.commit_ref_keywords = '*'
    Setting.commit_fix_keywords = ''

    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => 'Ignores #2. Refs #1')
    c.scan_comment_for_issue_ids

    assert_equal [1, 2], c.issue_ids.sort
  end

  def test_ref_keywords_any_with_timelog
    Setting.commit_ref_keywords = '*'
    Setting.commit_logtime_enabled = '1'

    {
      '2' => 2.0,
      '2h' => 2.0,
      '2hours' => 2.0,
      '15m' => 0.25,
      '15min' => 0.25,
      '3h15' => 3.25,
      '3h15m' => 3.25,
      '3h15min' => 3.25,
      '3:15' => 3.25,
      '3.25' => 3.25,
      '3.25h' => 3.25,
      '3,25' => 3.25,
      '3,25h' => 3.25,
    }.each do |syntax, expected_hours|
      c = Changeset.new(:repository => Project.find(1).repository,
                        :committed_on => 24.hours.ago,
                        :comments => "Worked on this issue #1 @#{syntax}",
                        :revision => '520',
                        :user => User.find(2))
      assert_difference 'TimeEntry.count' do
        c.scan_comment_for_issue_ids
      end
      assert_equal [1], c.issue_ids.sort

      time = TimeEntry.first(:order => 'id desc')
      assert_equal 1, time.issue_id
      assert_equal 1, time.project_id
      assert_equal 2, time.user_id
      assert_equal expected_hours, time.hours, "@#{syntax} should be logged as #{expected_hours} hours but was #{time.hours}"
      assert_equal Date.yesterday, time.spent_on
      assert time.activity.is_default?
      assert time.comments.include?('r520'), "r520 was expected in time_entry comments: #{time.comments}"
    end
  end

  def test_ref_keywords_closing_with_timelog
    Setting.commit_fix_status_id = IssueStatus.find(:first, :conditions => ["is_closed = ?", true]).id
    Setting.commit_ref_keywords = '*'
    Setting.commit_fix_keywords = 'fixes , closes'
    Setting.commit_logtime_enabled = '1'

    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => 'This is a comment. Fixes #1 @4.5, #2 @1',
                      :user => User.find(2))
    assert_difference 'TimeEntry.count', 2 do
      c.scan_comment_for_issue_ids
    end

    assert_equal [1, 2], c.issue_ids.sort
    assert Issue.find(1).closed?
    assert Issue.find(2).closed?

    times = TimeEntry.all(:order => 'id desc', :limit => 2)
    assert_equal [1, 2], times.collect(&:issue_id).sort
  end

  def test_ref_keywords_any_line_start
    Setting.commit_ref_keywords = '*'

    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => '#1 is the reason of this commit')
    c.scan_comment_for_issue_ids

    assert_equal [1], c.issue_ids.sort
  end

  def test_ref_keywords_allow_brackets_around_a_issue_number
    Setting.commit_ref_keywords = '*'

    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => '[#1] Worked on this issue')
    c.scan_comment_for_issue_ids

    assert_equal [1], c.issue_ids.sort
  end

  def test_ref_keywords_allow_brackets_around_multiple_issue_numbers
    Setting.commit_ref_keywords = '*'

    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => '[#1 #2, #3] Worked on these')
    c.scan_comment_for_issue_ids

    assert_equal [1,2,3], c.issue_ids.sort
  end

  def test_commit_referencing_a_subproject_issue
    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => 'refs #5, a subproject issue')
    c.scan_comment_for_issue_ids

    assert_equal [5], c.issue_ids.sort
    assert c.issues.first.project != c.project
  end

  def test_commit_referencing_a_parent_project_issue
    # repository of child project
    r = Repository::Subversion.create!(
          :project => Project.find(3),
          :url     => 'svn://localhost/test')

    c = Changeset.new(:repository => r,
                      :committed_on => Time.now,
                      :comments => 'refs #2, an issue of a parent project')
    c.scan_comment_for_issue_ids

    assert_equal [2], c.issue_ids.sort
    assert c.issues.first.project != c.project
  end

  def test_text_tag_revision
    c = Changeset.new(:revision => '520')
    assert_equal 'r520', c.text_tag
  end

  def test_text_tag_hash
    c = Changeset.new(
          :scmid    => '7234cb2750b63f47bff735edc50a1c0a433c2518',
          :revision => '7234cb2750b63f47bff735edc50a1c0a433c2518')
    assert_equal 'commit:7234cb2750b63f47bff735edc50a1c0a433c2518', c.text_tag
  end

  def test_text_tag_hash_all_number
    c = Changeset.new(:scmid => '0123456789', :revision => '0123456789')
    assert_equal 'commit:0123456789', c.text_tag
  end

  def test_previous
    changeset = Changeset.find_by_revision('3')
    assert_equal Changeset.find_by_revision('2'), changeset.previous
  end

  def test_previous_nil
    changeset = Changeset.find_by_revision('1')
    assert_nil changeset.previous
  end

  def test_next
    changeset = Changeset.find_by_revision('2')
    assert_equal Changeset.find_by_revision('3'), changeset.next
  end

  def test_next_nil
    changeset = Changeset.find_by_revision('10')
    assert_nil changeset.next
  end

  def test_comments_should_be_converted_to_utf8
      proj = Project.find(3)
      str = File.read("#{RAILS_ROOT}/test/fixtures/encoding/iso-8859-1.txt")
      r = Repository::Bazaar.create!(
            :project => proj, :url => '/tmp/test/bazaar',
            :log_encoding => 'ISO-8859-1' )
      assert r
      c = Changeset.new(:repository => r,
                        :committed_on => Time.now,
                        :revision => '123',
                        :scmid => '12345',
                        :comments => str)
      assert( c.save )
      assert_equal "Texte encodé en ISO-8859-1.", c.comments
  end

  def test_invalid_utf8_sequences_in_comments_should_be_replaced_latin1
      proj = Project.find(3)
      str = File.read("#{RAILS_ROOT}/test/fixtures/encoding/iso-8859-1.txt")
      r = Repository::Bazaar.create!(
            :project => proj,
            :url => '/tmp/test/bazaar',
            :log_encoding => 'UTF-8' )
      assert r
      c = Changeset.new(:repository   => r,
                        :committed_on => Time.now,
                        :revision     => '123',
                        :scmid        => '12345',
                        :comments     => str)
      assert( c.save )
      assert_equal "Texte encod? en ISO-8859-1.", c.comments
  end

  def test_invalid_utf8_sequences_in_comments_should_be_replaced_ja_jis
      proj = Project.find(3)
      str = "test\xb5\xfetest\xb5\xfe"
      if str.respond_to?(:force_encoding)
        str.force_encoding('ASCII-8BIT')
      end
      r = Repository::Bazaar.create!(
            :project => proj,
            :url     => '/tmp/test/bazaar',
            :log_encoding => 'ISO-2022-JP' )
      assert r
      c = Changeset.new(:repository   => r,
                        :committed_on => Time.now,
                        :revision     => '123',
                        :scmid        => '12345',
                        :comments     => str)
      assert( c.save )
      assert_equal "test??test??", c.comments
  end

  def test_comments_should_be_converted_all_latin1_to_utf8
      s1 = "\xC2\x80"
      s2 = "\xc3\x82\xc2\x80"
      s4 = s2.dup
      if s1.respond_to?(:force_encoding)
        s3 = s1.dup
        s1.force_encoding('ASCII-8BIT')
        s2.force_encoding('ASCII-8BIT')
        s3.force_encoding('ISO-8859-1')
        s4.force_encoding('UTF-8')
        assert_equal s3.encode('UTF-8'), s4
      end
      proj = Project.find(3)
      r = Repository::Bazaar.create!(
            :project => proj, :url => '/tmp/test/bazaar',
            :log_encoding => 'ISO-8859-1' )
      assert r
      c = Changeset.new(:repository => r,
                        :committed_on => Time.now,
                        :revision => '123',
                        :scmid => '12345',
                        :comments => s1)
      assert( c.save )
      assert_equal s4, c.comments
  end

  def test_comments_nil
      proj = Project.find(3)
      r = Repository::Bazaar.create!(
            :project => proj, :url => '/tmp/test/bazaar',
            :log_encoding => 'ISO-8859-1' )
      assert r
      c = Changeset.new(:repository => r,
                        :committed_on => Time.now,
                        :revision => '123',
                        :scmid => '12345',
                        :comments => nil)
      assert( c.save )
      assert_equal "", c.comments
      if c.comments.respond_to?(:force_encoding)
        assert_equal "UTF-8", c.comments.encoding.to_s
      end
  end

  def test_comments_empty
      proj = Project.find(3)
      r = Repository::Bazaar.create!(
            :project => proj, :url => '/tmp/test/bazaar',
            :log_encoding => 'ISO-8859-1' )
      assert r
      c = Changeset.new(:repository => r,
                        :committed_on => Time.now,
                        :revision => '123',
                        :scmid => '12345',
                        :comments => "")
      assert( c.save )
      assert_equal "", c.comments
      if c.comments.respond_to?(:force_encoding)
        assert_equal "UTF-8", c.comments.encoding.to_s
      end
  end

  def test_identifier
    c = Changeset.find_by_revision('1')
    assert_equal c.revision, c.identifier
  end
end
