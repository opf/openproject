# encoding: UTF-8

require 'test_helper'

adapter = ENV['ADAPTER'] || 'activerecord'
require File.join(File.expand_path(File.dirname(__FILE__)), "acts_as_url/adapter/#{adapter}.rb")

class ActsAsUrlIntegrationTest < Test::Unit::TestCase
  include AdapterSpecificTestBehaviors

  def test_should_create_url
    @doc = Document.create(title: "Let's Make a Test Title, <em>Okay</em>?")
    assert_equal "lets-make-a-test-title-okay", @doc.url
  end

  def test_should_create_unique_url
    @doc = Document.create(title: "Unique")
    @other_doc = Document.create(title: "Unique")
    assert_equal "unique", @doc.url
    assert_equal "unique-1", @other_doc.url
  end

  def test_should_allow_custom_duplicates
    sequence = Enumerator.new { |enum| loop { enum.yield 12345 } }
    Document.class_eval do
      acts_as_url :title, duplicate_sequence: sequence
    end

    @doc = Document.create(title: "New")
    @other_doc = Document.create(title: "New")
    assert_equal "new-document", @doc.url
    assert_equal "new-document-12345", @other_doc.url
  end

  def test_should_restart_duplicate_sequence_each_time
    sequence = Enumerator.new do |enum|
      n = 1
      loop do
        enum.yield n
        n += 1
      end
    end
    Document.class_eval do
      acts_as_url :title, duplicate_sequence: sequence
    end
    @doc = Document.create(title: "Unique")
    @other_doc = Document.create(title: "Unique")
    @third_doc = Document.create(title: "Another")
    @fourth_doc = Document.create(title: "Another")
    assert_equal "unique", @doc.url
    assert_equal "unique-1", @other_doc.url
    assert_equal "another", @third_doc.url
    assert_equal "another-1", @fourth_doc.url
  end

  def test_should_avoid_blacklist
    @doc = Document.create(title: "New")
    @other_doc = Document.create(title: "new")
    assert_equal "new-document", @doc.url
    assert_equal "new-document-1", @other_doc.url
  end

  def test_should_allow_customizing_blacklist
    Document.class_eval do
      # Un-blacklisting 'new' isn't advisable
      acts_as_url :title, blacklist: %w{special}
    end

    @doc = Document.create(title: "New")
    @other_doc = Document.create(title: "Special")
    assert_equal 'new', @doc.url
    assert_equal 'special-document', @other_doc.url
  end

  def test_should_allow_customizing_blacklist_policy
    Document.class_eval do
      acts_as_url :title, blacklist_policy: Proc.new(){|instance, url|
        "#{url}-customized"
      }
    end

    @doc = Document.create(title: "New")
    @other_doc = Document.create(title: "New")
    assert_equal 'new-customized', @doc.url
    assert_equal 'new-customized-1', @other_doc.url
  end

  def test_should_create_unique_url_when_partial_url_already_exists
    @doc = Document.create(title: "House Farms")
    @other_doc = Document.create(title: "House Farm")

    assert_equal "house-farms", @doc.url
    assert_equal "house-farm", @other_doc.url
  end

  def test_should_not_sync_url_by_default
    @doc = Document.create(title: "Stable as Stone")
    @original_url = @doc.url
    adapter_specific_update @doc, title: "New Unstable Madness"
    assert_equal @original_url, @doc.url
  end

  def test_should_allow_syncing_url
    Document.class_eval do
      acts_as_url :title, sync_url: true
    end

    @doc = Document.create(title: "Original")
    @original_url = @doc.url
    adapter_specific_update @doc, title: "New and Improved"
    assert_not_equal @original_url, @doc.url
  end

  def test_should_not_increment_count_on_repeated_saves
    Document.class_eval do
      acts_as_url :title, sync_url: true
    end

    @doc = Document.create(title: "Continuous or Constant")
    assert_equal "continuous-or-constant", @doc.url
    5.times do |n|
      @doc.save!
      assert_equal "continuous-or-constant", @doc.url
    end
  end

  def test_should_allow_allowing_duplicate_url
    Document.class_eval do
      acts_as_url :title, allow_duplicates: true
    end

    @doc = Document.create(title: "I am not a clone")
    @other_doc = Document.create(title: "I am not a clone")
    assert_equal @doc.url, @other_doc.url
  end

  def test_should_allow_scoping_url_uniqueness
    Document.class_eval do
      acts_as_url :title, scope: :other
    end

    @doc = Document.create(title: "Mocumentary", other: "I don't care if I'm unique for some reason")
    @other_doc = Document.create(title: "Mocumentary", other: "Me either")
    assert_equal @doc.url, @other_doc.url
  end

  def test_should_still_create_unique_urls_if_scoped_attribute_is_the_same
    Document.class_eval do
      acts_as_url :title, scope: :other
    end

    @doc = Document.create(title: "Mocumentary", other: "Suddenly, I care if I'm unique")
    @other_doc = Document.create(title: "Mocumentary", other: "Suddenly, I care if I'm unique")
    assert_not_equal @doc.url, @other_doc.url
  end

  def test_should_allow_multiple_scopes
    Document.class_eval do
      acts_as_url :title, scope: [:other, :another]
    end

    @doc = Document.create(title: "Mocumentary", other: "I don't care if I'm unique for some reason",
      another: "Whatever")
    @other_doc = Document.create(title: "Mocumentary", other: "Me either", another: "Whatever")
    assert_equal @doc.url, @other_doc.url
  end

  def test_should_only_create_unique_urls_for_multiple_scopes_if_both_attributes_are_same
    Document.class_eval do
      acts_as_url :title, scope: [:other, :another]
    end

    @doc = Document.create(title: "Mocumentary", other: "Suddenly, I care if I'm unique",
      another: "Whatever")
    @other_doc = Document.create(title: "Mocumentary", other: "Suddenly, I care if I'm unique",
      another: "Whatever")
    assert_not_equal @doc.url, @other_doc.url
  end

  def test_should_allow_setting_url_attribute
    Document.class_eval do
      # Manually undefining the url method on Document which, in a real class not reused for tests,
      # would never have been defined to begin with.
      remove_method :url
      acts_as_url :title, url_attribute: :other
    end

    @doc = Document.create(title: "Anything at This Point")
    assert_equal "anything-at-this-point", @doc.other
    assert_nil @doc.url
  ensure
    Document.class_eval do
      # Manually undefining the other method on Document for the same reasons as before
      remove_method :other
    end
  end

  def test_should_allow_updating_url_only_when_blank
    Document.class_eval do
      acts_as_url :title, only_when_blank: true
    end

    @string = 'the-url-of-concrete'
    @doc = Document.create(title: "Stable as Stone", url: @string)
    assert_equal @string, @doc.url
    @other_doc = Document.create(title: "Stable as Stone")
    assert_equal 'stable-as-stone', @other_doc.url
  end

  def test_should_mass_initialize_urls
    @doc = Document.create(title: "Initial")
    @other_doc = Document.create(title: "Subsequent")
    adapter_specific_update @doc, url: nil
    adapter_specific_update @other_doc, url: nil
    # Just making sure this got unset before the real test
    assert_nil @doc.url
    assert_nil @other_doc.url

    Document.initialize_urls

    @doc.reload
    @other_doc.reload
    assert_equal "initial", @doc.url
    assert_equal "subsequent", @other_doc.url
  end

  def test_should_mass_initialize_urls_with_custom_url_attribute
    Document.class_eval do
      # Manually undefining the url method on Document which, in a real class not reused for tests,
      # would never have been defined to begin with.
      remove_method :url
      acts_as_url :title, url_attribute: :other
    end

    @doc = Document.create(title: "Initial")
    @other_doc = Document.create(title: "Subsequent")
    adapter_specific_update @doc, other: nil
    adapter_specific_update @other_doc, other: nil
    # Just making sure this got unset before the real test
    assert_nil @doc.other
    assert_nil @other_doc.other

    Document.initialize_urls

    @doc.reload
    @other_doc.reload
    assert_equal "initial", @doc.other
    assert_equal "subsequent", @other_doc.other
  ensure
    Document.class_eval do
      # Manually undefining the other method on Document for the same reasons as before
      remove_method :other
    end
  end

  def test_should_mass_initialize_empty_string_urls
    @doc = Document.create(title: "Initial")
    @other_doc = Document.create(title: "Subsequent")
    adapter_specific_update @doc, url: ''
    adapter_specific_update @other_doc, url: ''
    # Just making sure this got unset before the real test
    assert_equal '', @doc.url
    assert_equal '', @other_doc.url

    Document.initialize_urls

    @doc.reload
    @other_doc.reload
    assert_equal "initial", @doc.url
    assert_equal "subsequent", @other_doc.url
  end

  def test_should_allow_using_custom_method_for_generating_url
    Document.class_eval do
      acts_as_url :non_attribute_method

      def non_attribute_method
        "#{title} got massaged"
      end
    end

    @doc = Document.create(title: "Title String")
    assert_equal "title-string-got-massaged", @doc.url
  ensure
    Document.class_eval do
      # Manually undefining method that isn't defined on Document by default
      remove_method :non_attribute_method
    end
  end

  def test_should_allow_customizing_duplicate_count_separator
    Document.class_eval do
      acts_as_url :title, duplicate_count_separator: "---"
    end

    @doc = Document.create(title: "Unique")
    @other_doc = Document.create(title: "Unique")
    assert_equal "unique", @doc.url
    assert_equal "unique---1", @other_doc.url
  end

  def test_should_only_update_url_if_url_attribute_is_valid
    Document.class_eval do
      acts_as_url :title, sync_url: true
    end
    add_validation_on_document_title

    @doc = Document.create(title: "Valid Record", other: "Present")
    assert_equal "valid-record", @doc.url
    @doc.title = nil
    assert_equal false, @doc.valid?
    assert_equal "valid-record", @doc.url
  ensure
    remove_validation_on_document_title
  end

  def test_should_allow_customizing_url_limit
    Document.class_eval do
      acts_as_url :title, limit: 13
    end

    @doc = Document.create(title: "I am much too long")
    assert_equal "i-am-much-too", @doc.url
  end

  def test_handling_duplicate_urls_with_limits
    Document.class_eval do
      acts_as_url :title, limit: 13
    end

    @doc = Document.create(title: "I am much too long and also duplicated")
    assert_equal "i-am-much-too", @doc.url
    @other_doc = Document.create(title: "I am much too long and also duplicated")
    assert_equal "i-am-much-too-1", @other_doc.url
  end

  def test_should_allow_excluding_specific_values_from_being_run_through_to_url
    Document.class_eval do
      acts_as_url :title, exclude: ["_So_Fucking_Special"]
    end

    @doc = Document.create(title: "_So_Fucking_Special")
    assert_equal "_So_Fucking_Special", @doc.url
    @doc_2 = Document.create(title: "But I'm a creep")
    assert_equal "but-im-a-creep", @doc_2.url
  end

  def test_should_allow_not_forcing_downcasing
    Document.class_eval do
      acts_as_url :title, force_downcase: false
    end

    @doc = Document.create(title: "I have CAPS!")
    assert_equal "I-have-CAPS", @doc.url
  end

  def test_should_allow_alternate_whitespace_replacements
    Document.class_eval do
      acts_as_url :title, replace_whitespace_with: "~"
    end

    @doc = Document.create(title: "now with tildes")
    assert_equal "now~with~tildes", @doc.url
  end

  def test_should_allow_enforcing_uniqueness_on_sti_base_class
    STIBaseDocument.class_eval do
      acts_as_url :title, enforce_uniqueness_on_sti_base_class: true
    end

    @doc = STIChildDocument.create(title: "Unique")
    assert_equal "unique", @doc.url
    @doc_2 = AnotherSTIChildDocument.create(title: "Unique")
    assert_equal "unique-1", @doc_2.url
  end

  def test_should_strip_slashes_by_default
    Document.class_eval do
      acts_as_url :title
    end

    @doc = Document.create(title: "a b/c d")
    assert_equal "a-b-slash-c-d", @doc.url
  end

  def test_should_allow_slashes_to_be_allowed
    Document.class_eval do
      acts_as_url :title, allow_slash: true
    end

    @doc = Document.create(title: "a b/c d")
    assert_equal "a-b/c-d", @doc.url
  end

  def test_should_truncate_words_by_default
    Document.class_eval do
      acts_as_url :title, limit: 20
    end

    @doc = Document.create(title: "title with many whole words")
    assert_equal 'title-with-many-whol', @doc.url
  end

  def test_should_not_truncate_words
    Document.class_eval do
      acts_as_url :title, limit: 20, truncate_words: false
    end

    @doc = Document.create(title: "title with many whole words")
    assert_equal 'title-with-many', @doc.url
  end

  def test_should_allow_overriding_url_taken_method
    Document.class_eval do
      acts_as_url :title, url_taken_method: :url_taken?

      def url_taken?(url)
        ["unique", "unique-1", "unique-2"].include?(url)
      end
    end

    @doc = Document.create(title: "unique")
    assert_equal "unique-3", @doc.url
  end
end
