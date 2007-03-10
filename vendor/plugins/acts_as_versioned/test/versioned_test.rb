require File.join(File.dirname(__FILE__), 'abstract_unit')
require File.join(File.dirname(__FILE__), 'fixtures/page')
require File.join(File.dirname(__FILE__), 'fixtures/widget')

class VersionedTest < Test::Unit::TestCase
  fixtures :pages, :page_versions, :locked_pages, :locked_pages_revisions, :authors, :landmarks, :landmark_versions

  def test_saves_versioned_copy
    p = Page.create :title => 'first title', :body => 'first body'
    assert !p.new_record?
    assert_equal 1, p.versions.size
    assert_equal 1, p.version
    assert_instance_of Page.versioned_class, p.versions.first
  end

  def test_saves_without_revision
    p = pages(:welcome)
    old_versions = p.versions.count
    
    p.save_without_revision
    
    p.without_revision do
      p.update_attributes :title => 'changed'
    end
    
    assert_equal old_versions, p.versions.count
  end

  def test_rollback_with_version_number
    p = pages(:welcome)
    assert_equal 24, p.version
    assert_equal 'Welcome to the weblog', p.title
    
    assert p.revert_to!(p.versions.first.version), "Couldn't revert to 23"
    assert_equal 23, p.version
    assert_equal 'Welcome to the weblg', p.title
  end

  def test_versioned_class_name
    assert_equal 'Version', Page.versioned_class_name
    assert_equal 'LockedPageRevision', LockedPage.versioned_class_name
  end

  def test_versioned_class
    assert_equal Page::Version,                  Page.versioned_class
    assert_equal LockedPage::LockedPageRevision, LockedPage.versioned_class
  end

  def test_special_methods
    assert_nothing_raised { pages(:welcome).feeling_good? }
    assert_nothing_raised { pages(:welcome).versions.first.feeling_good? }
    assert_nothing_raised { locked_pages(:welcome).hello_world }
    assert_nothing_raised { locked_pages(:welcome).versions.first.hello_world }
  end

  def test_rollback_with_version_class
    p = pages(:welcome)
    assert_equal 24, p.version
    assert_equal 'Welcome to the weblog', p.title
    
    assert p.revert_to!(p.versions.first), "Couldn't revert to 23"
    assert_equal 23, p.version
    assert_equal 'Welcome to the weblg', p.title
  end
  
  def test_rollback_fails_with_invalid_revision
    p = locked_pages(:welcome)
    assert !p.revert_to!(locked_pages(:thinking))
  end

  def test_saves_versioned_copy_with_options
    p = LockedPage.create :title => 'first title'
    assert !p.new_record?
    assert_equal 1, p.versions.size
    assert_instance_of LockedPage.versioned_class, p.versions.first
  end
  
  def test_rollback_with_version_number_with_options
    p = locked_pages(:welcome)
    assert_equal 'Welcome to the weblog', p.title
    assert_equal 'LockedPage', p.versions.first.version_type
    
    assert p.revert_to!(p.versions.first.version), "Couldn't revert to 23"
    assert_equal 'Welcome to the weblg', p.title
    assert_equal 'LockedPage', p.versions.first.version_type
  end
  
  def test_rollback_with_version_class_with_options
    p = locked_pages(:welcome)
    assert_equal 'Welcome to the weblog', p.title
    assert_equal 'LockedPage', p.versions.first.version_type
    
    assert p.revert_to!(p.versions.first), "Couldn't revert to 1"
    assert_equal 'Welcome to the weblg', p.title
    assert_equal 'LockedPage', p.versions.first.version_type
  end
  
  def test_saves_versioned_copy_with_sti
    p = SpecialLockedPage.create :title => 'first title'
    assert !p.new_record?
    assert_equal 1, p.versions.size
    assert_instance_of LockedPage.versioned_class, p.versions.first
    assert_equal 'SpecialLockedPage', p.versions.first.version_type
  end
  
  def test_rollback_with_version_number_with_sti
    p = locked_pages(:thinking)
    assert_equal 'So I was thinking', p.title
    
    assert p.revert_to!(p.versions.first.version), "Couldn't revert to 1"
    assert_equal 'So I was thinking!!!', p.title
    assert_equal 'SpecialLockedPage', p.versions.first.version_type
  end

  def test_lock_version_works_with_versioning
    p = locked_pages(:thinking)
    p2 = LockedPage.find(p.id)
    
    p.title = 'fresh title'
    p.save
    assert_equal 2, p.versions.size # limit!
    
    assert_raises(ActiveRecord::StaleObjectError) do
      p2.title = 'stale title'
      p2.save
    end
  end

  def test_version_if_condition
    p = Page.create :title => "title"
    assert_equal 1, p.version
    
    Page.feeling_good = false
    p.save
    assert_equal 1, p.version
    Page.feeling_good = true
  end
  
  def test_version_if_condition2
    # set new if condition
    Page.class_eval do
      def new_feeling_good() title[0..0] == 'a'; end
      alias_method :old_feeling_good, :feeling_good?
      alias_method :feeling_good?, :new_feeling_good
    end
    
    p = Page.create :title => "title"
    assert_equal 1, p.version # version does not increment
    assert_equal 1, p.versions(true).size
    
    p.update_attributes(:title => 'new title')
    assert_equal 1, p.version # version does not increment
    assert_equal 1, p.versions(true).size
    
    p.update_attributes(:title => 'a title')
    assert_equal 2, p.version
    assert_equal 2, p.versions(true).size
    
    # reset original if condition
    Page.class_eval { alias_method :feeling_good?, :old_feeling_good }
  end
  
  def test_version_if_condition_with_block
    # set new if condition
    old_condition = Page.version_condition
    Page.version_condition = Proc.new { |page| page.title[0..0] == 'b' }
    
    p = Page.create :title => "title"
    assert_equal 1, p.version # version does not increment
    assert_equal 1, p.versions(true).size
    
    p.update_attributes(:title => 'a title')
    assert_equal 1, p.version # version does not increment
    assert_equal 1, p.versions(true).size
    
    p.update_attributes(:title => 'b title')
    assert_equal 2, p.version
    assert_equal 2, p.versions(true).size
    
    # reset original if condition
    Page.version_condition = old_condition
  end

  def test_version_no_limit
    p = Page.create :title => "title", :body => 'first body'
    p.save
    p.save
    5.times do |i|
      assert_page_title p, i
    end
  end

  def test_version_max_limit
    p = LockedPage.create :title => "title"
    p.update_attributes(:title => "title1")
    p.update_attributes(:title => "title2")
    5.times do |i|
      assert_page_title p, i, :lock_version
      assert p.versions(true).size <= 2, "locked version can only store 2 versions"
    end
  end
  
  def test_track_changed_attributes_default_value
    assert !Page.track_changed_attributes
    assert LockedPage.track_changed_attributes
    assert SpecialLockedPage.track_changed_attributes
  end
  
  def test_version_order
    assert_equal 23, pages(:welcome).versions.first.version
    assert_equal 24, pages(:welcome).versions.last.version
    assert_equal 23, pages(:welcome).find_versions.first.version
    assert_equal 24, pages(:welcome).find_versions.last.version
  end
  
  def test_track_changed_attributes    
    p = LockedPage.create :title => "title"
    assert_equal 1, p.lock_version
    assert_equal 1, p.versions(true).size
    
    p.title = 'title'
    assert !p.save_version?
    p.save
    assert_equal 2, p.lock_version # still increments version because of optimistic locking
    assert_equal 1, p.versions(true).size
    
    p.title = 'updated title'
    assert p.save_version?
    p.save
    assert_equal 3, p.lock_version
    assert_equal 1, p.versions(true).size # version 1 deleted

    p.title = 'updated title!'
    assert p.save_version?
    p.save
    assert_equal 4, p.lock_version
    assert_equal 2, p.versions(true).size # version 1 deleted
  end
    
  def assert_page_title(p, i, version_field = :version)
    p.title = "title#{i}"
    p.save
    assert_equal "title#{i}", p.title
    assert_equal (i+4), p.send(version_field)
  end
  
  def test_find_versions
    assert_equal 2, locked_pages(:welcome).versions.size
    assert_equal 1, locked_pages(:welcome).find_versions(:conditions => ['title LIKE ?', '%weblog%']).length
    assert_equal 2, locked_pages(:welcome).find_versions(:conditions => ['title LIKE ?', '%web%']).length
    assert_equal 0, locked_pages(:thinking).find_versions(:conditions => ['title LIKE ?', '%web%']).length
    assert_equal 2, locked_pages(:welcome).find_versions.length
  end
  
  def test_with_sequence
    assert_equal 'widgets_seq', Widget.versioned_class.sequence_name
    Widget.create :name => 'new widget'
    Widget.create :name => 'new widget'
    Widget.create :name => 'new widget'
    assert_equal 3, Widget.count
    assert_equal 3, Widget.versioned_class.count
  end

  def test_has_many_through
    assert_equal [authors(:caged), authors(:mly)], pages(:welcome).authors
  end

  def test_has_many_through_with_custom_association
    assert_equal [authors(:caged), authors(:mly)], pages(:welcome).revisors
  end
  
  def test_referential_integrity
    pages(:welcome).destroy
    assert_equal 0, Page.count
    assert_equal 0, Page::Version.count
  end
  
  def test_association_options
    association = Page.reflect_on_association(:versions)
    options = association.options
    assert_equal :delete_all, options[:dependent]
    assert_equal 'version', options[:order]
    
    association = Widget.reflect_on_association(:versions)
    options = association.options
    assert_nil options[:dependent]
    assert_equal 'version desc', options[:order]
    assert_equal 'widget_id', options[:foreign_key]
    
    widget = Widget.create :name => 'new widget'
    assert_equal 1, Widget.count
    assert_equal 1, Widget.versioned_class.count
    widget.destroy
    assert_equal 0, Widget.count
    assert_equal 1, Widget.versioned_class.count
  end

  def test_versioned_records_should_belong_to_parent
    page = pages(:welcome)
    page_version = page.versions.last
    assert_equal page, page_version.page
  end
  
  def test_unchanged_attributes
    landmarks(:washington).attributes = landmarks(:washington).attributes
    assert !landmarks(:washington).changed?
  end
  
  def test_unchanged_string_attributes
    landmarks(:washington).attributes = landmarks(:washington).attributes.inject({}) { |params, (key, value)| params.update key => value.to_s }
    assert !landmarks(:washington).changed?
  end
end
