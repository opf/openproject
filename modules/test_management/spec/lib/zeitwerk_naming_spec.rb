# frozen_string_literal: true

require "spec_helper"

# Regression (0014b): a file whose name does not match the constant Zeitwerk expects is never
# autoloaded (assistant/sources/base.rb defined Sources::Error instead of Sources::Base), and a
# migration class must match ActiveSupport's camelize with OpenProject's acronyms
# ("..._test_ai_..." => "TestAI"). Eager loading the module and requiring each migration
# catches both before they reach a running instance.
RSpec.describe "Test management constant naming" do # rubocop:disable RSpec/DescribeClass
  let(:root) { OpenProject::TestManagement::Engine.root }

  it "eager loads every autoloaded directory of the module" do
    Dir[root.join("app/*")].reject { |dir| dir.end_with?("/views", "/assets") }.each do |dir|
      expect { Rails.autoloaders.main.eager_load_dir(dir) }.not_to raise_error
    end
  end

  it "names every migration class after its file" do
    Dir[root.join("db/migrate/*.rb")].each do |file|
      require file
      class_name = File.basename(file, ".rb").sub(/\A\d+_/, "").camelize
      expect(Object.const_defined?(class_name)).to be(true), "#{File.basename(file)} should define #{class_name}"
    end
  end
end
