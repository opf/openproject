# frozen_string_literal: true

require "spec_helper"
require "open_project/api_doc_coverage/path_normalizer"

RSpec.describe OpenProject::ApiDocCoverage::PathNormalizer do
  describe ".canonical_path" do
    it "maps a Grape member route to the /api/v3 OpenAPI form" do
      expect(described_class.canonical_path("/:version/work_packages/:id(.:format)"))
        .to eq("/api/v3/work_packages/{id}")
    end

    it "maps a collection route" do
      expect(described_class.canonical_path("/:version/work_packages(.:format)"))
        .to eq("/api/v3/work_packages")
    end

    it "handles nested and multi-param paths" do
      expect(described_class.canonical_path("/:version/projects/:project_id/versions/:id(.:format)"))
        .to eq("/api/v3/projects/{project_id}/versions/{id}")
    end

    it "handles the bare version root" do
      expect(described_class.canonical_path("/:version(.:format)")).to eq("/api/v3")
    end
  end

  describe ".module_name" do
    it "returns the first segment after /api/v3" do
      expect(described_class.module_name("/api/v3/work_packages/{id}")).to eq("work_packages")
    end

    it "returns (root) for the bare version root" do
      expect(described_class.module_name("/api/v3")).to eq("(root)")
    end
  end
end
