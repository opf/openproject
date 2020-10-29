module FriendlyId
  module Test
    module Shared

      module Slugged
        test "configuration should have a sequence_separator" do
          assert !model_class.friendly_id_config.sequence_separator.empty?
        end

        test "should make a new slug if the slug has been set to nil changed" do
          with_instance_of model_class do |record|
            record.name = "Changed Value"
            record.slug = nil
            record.save!
            assert_equal "changed-value", record.slug
          end
        end

        test "should add a UUID for duplicate friendly ids" do
          with_instance_of model_class do |record|
            record2 = model_class.create! :name => record.name
            assert record2.friendly_id.match(/([0-9a-z]+\-){4}[0-9a-z]+\z/)
          end
        end

        test "should not add slug sequence on update after other conflicting slugs were added" do
          with_instance_of model_class do |record|
            old = record.friendly_id
            model_class.create! :name => record.name
            record.save!
            record.reload
            assert_equal old, record.to_param
          end
        end

        test "should not change the sequence on save" do
          with_instance_of model_class do |record|
            record2 = model_class.create! :name => record.name
            friendly_id = record2.friendly_id
            record2.active = !record2.active
            record2.save!
            assert_equal friendly_id, record2.reload.friendly_id
          end
        end

        test "should create slug on save if the slug is nil" do
          with_instance_of model_class do |record|
            record.slug = nil
            record.save!
            refute_nil record.slug
          end
        end

        test "should set the slug to nil on dup" do
          with_instance_of model_class do |record|
            record2 = record.dup
            assert_nil record2.slug
          end
        end

        test "when validations block save, to_param should return friendly_id rather than nil" do
          my_model_class = Class.new(model_class)
          self.class.const_set("Foo", my_model_class)
          with_instance_of my_model_class do |record|
            record.update my_model_class.friendly_id_config.slug_column => nil
            record = my_model_class.friendly.find(record.id)
            record.class.validate Proc.new {errors.add(:name, "FAIL")}
            record.save
            assert_equal record.to_param, record.friendly_id
          end
        end
      end

      module Core
        test "finds should respect conditions" do
          with_instance_of(model_class) do |record|
            assert_raises(ActiveRecord::RecordNotFound) do
              model_class.where("1 = 2").friendly.find record.friendly_id
            end
            assert_raises(ActiveRecord::RecordNotFound) do
              model_class.where("1 = 2").friendly.find record.id
            end
          end
        end

        test "should be findable by friendly id" do
          with_instance_of(model_class) {|record| assert model_class.friendly.find record.friendly_id}
        end

        test "should exist? by friendly id" do
          with_instance_of(model_class) do |record|
            assert model_class.friendly.exists? record.id
            assert model_class.friendly.exists? record.id.to_s
            assert model_class.friendly.exists? record.friendly_id
            assert model_class.friendly.exists?({:id => record.id})
            assert model_class.friendly.exists?(['id = ?', record.id])
            assert !model_class.friendly.exists?(record.friendly_id + "-hello")
            assert !model_class.friendly.exists?(0)
          end
        end

        test "should be findable by id as integer" do
          with_instance_of(model_class) {|record| assert model_class.friendly.find record.id.to_i}
        end

        test "should be findable by id as string" do
          with_instance_of(model_class) {|record| assert model_class.friendly.find record.id.to_s}
        end

        test "should treat numeric part of string as an integer id" do
          with_instance_of(model_class) do |record|
            assert_raises(ActiveRecord::RecordNotFound) do
              model_class.friendly.find "#{record.id}-foo"
            end
          end
        end

        test "should be findable by numeric friendly_id" do
          with_instance_of(model_class, :name => "206") {|record| assert model_class.friendly.find record.friendly_id}
        end

        test "to_param should return the friendly_id" do
          with_instance_of(model_class) {|record| assert_equal record.friendly_id, record.to_param}
        end

        if ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR < 2
          test "should be findable by themselves" do
            with_instance_of(model_class) {|record| assert_equal record, model_class.friendly.find(record)}
          end
        end

        test "updating record's other values should not change the friendly_id" do
          with_instance_of model_class do |record|
            old = record.friendly_id
            record.update! active: false
            assert model_class.friendly.find old
          end
        end

        test "instances found by a single id should not be read-only" do
          with_instance_of(model_class) {|record| assert !model_class.friendly.find(record.friendly_id).readonly?}
        end

        test "failing finds with unfriendly_id should raise errors normally" do
          assert_raises(ActiveRecord::RecordNotFound) {model_class.friendly.find 0}
        end

        test "should return numeric id if the friendly_id is nil" do
          with_instance_of(model_class) do |record|
            record.expects(:friendly_id).returns(nil)
            assert_equal record.id.to_s, record.to_param
          end
        end

        test "should return numeric id if the friendly_id is an empty string" do
          with_instance_of(model_class) do |record|
            record.expects(:friendly_id).returns("")
            assert_equal record.id.to_s, record.to_param
          end
        end

        test "should return the friendly_id as a string" do
          with_instance_of(model_class) do |record|
            record.expects(:friendly_id).returns(5)
            assert_equal "5", record.to_param
          end
        end

        test "should return numeric id if the friendly_id is blank" do
          with_instance_of(model_class) do |record|
            record.expects(:friendly_id).returns("  ")
            assert_equal record.id.to_s, record.to_param
          end
        end

        test "should return nil for to_param with a new record" do
          assert_nil model_class.new.to_param
        end
      end
    end
  end
end
