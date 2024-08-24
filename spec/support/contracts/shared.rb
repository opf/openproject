RSpec.shared_context "model contract" do
  shared_examples_for "is not writable" do
    before do
      instance.model.attributes = { attribute => value }
    end

    it "explains the not writable error" do
      instance.validate
      expect(instance.errors.details[attribute])
        .to contain_exactly({ error: :error_readonly })
    end
  end

  shared_examples_for "is writable" do
    before do
      instance.model.attributes = { attribute => value }
    end

    it "is writable" do
      instance.validate

      expect(instance.errors.details[attribute])
        .not_to include(error: :error_readonly)
    end
  end
end
