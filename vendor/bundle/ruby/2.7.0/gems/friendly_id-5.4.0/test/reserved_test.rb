require "helper"

class ReservedTest < TestCaseClass

  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :slug_candidates, :use => [:slugged, :reserved], :reserved_words => %w(new edit)

    after_validation :move_friendly_id_error_to_name

    def move_friendly_id_error_to_name
      errors.add :name, *errors.delete(:friendly_id) if errors[:friendly_id].present?
    end

    def slug_candidates
      name
    end
  end

  def model_class
    Journalist
  end

  test "should reserve words" do
    %w(new edit NEW Edit).each do |word|
      transaction do
        assert_raises(ActiveRecord::RecordInvalid) {model_class.create! :name => word}
      end
    end
  end

  test "should move friendly_id error to name" do
    with_instance_of(model_class) do |record|
      record.errors.add :name, "xxx"
      record.errors.add :friendly_id, "yyy"
      record.move_friendly_id_error_to_name
      assert record.errors[:name].present? && record.errors[:friendly_id].blank?
      assert_equal 2, record.errors.count
    end
  end

  test "should reject reserved candidates" do
    transaction do
      record = model_class.new(:name => 'new')
      def record.slug_candidates
        [:name, "foo"]
      end
      record.save!
      assert_equal "foo", record.friendly_id
    end
  end

  test "should be invalid if all candidates are reserved" do
    transaction do
      record = model_class.new(:name => 'new')
      def record.slug_candidates
        ["edit", "new"]
      end
      assert_raises(ActiveRecord::RecordInvalid) {record.save!}
    end
  end

  test "should optionally treat reserved words as conflict" do
    klass = Class.new(model_class) do
      friendly_id :slug_candidates, :use => [:slugged, :reserved], :reserved_words => %w(new edit), :treat_reserved_as_conflict => true
    end

    with_instance_of(klass, name: 'new') do |record|
      assert_match(/new-([0-9a-z]+\-){4}[0-9a-z]+\z/, record.slug)
    end
  end

end
