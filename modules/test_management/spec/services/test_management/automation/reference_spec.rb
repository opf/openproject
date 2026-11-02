# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Automation::Reference do
  let(:names) { %w[shop api] }

  it "parses a qualified end-to-end reference" do
    reference = described_class.parse("shop/e2e:e2e/checkout.spec.ts#checkout › pays", names:)

    expect(reference).to be_qualified
    expect(reference).to be_e2e
    expect(reference).to have_attributes(name: "shop", path: "e2e/checkout.spec.ts", fragment: "checkout › pays")
  end

  it "keeps references unqualified unless the prefix names a connection" do
    ["Feature: Login#x", "a.spec.ts:12#x", "https://x.example.com/y", "other:tests/a.ts#x", "shop:12#x", "shop::x"].each do |raw|
      reference = described_class.parse(raw, names:)
      expect(reference).not_to be_qualified, raw
      expect(reference.body).to eq(raw)
    end
  end

  it "builds references" do
    expect(described_class.build("shop", "a#b")).to eq("shop:a#b")
    expect(described_class.build("shop", "a#b", e2e: true)).to eq("shop/e2e:a#b")
    expect(described_class.build(nil, "a#b")).to eq("a#b")
  end

  describe ".e2e?" do
    it "uses testType, then the connection setting, then the path" do
      expect(described_class.e2e?(path: "src/unit/a.ts", test_type: "e2e")).to be(true)
      expect(described_class.e2e?(path: "e2e/a.ts", test_type: "unit")).to be(false)
      expect(described_class.e2e?(path: "e2e/a.ts",
                                  connection: TestManagement::CiConnection.new(e2e_tests: "never"))).to be(false)
      expect(described_class.e2e?(path: "src/a.ts",
                                  connection: TestManagement::CiConnection.new(e2e_tests: "always"))).to be(true)
      expect(described_class.e2e?(path: "x.ts", format: "playwright_json")).to be(true)
    end

    it "detects e2e path segments and cypress" do
      %w[e2e/a.ts tests/e2e/a.ts checkout.e2e.ts checkout.e2e-spec.ts cypress/integration/a.cy.js].each do |path|
        expect(described_class.e2e?(path:)).to be(true), path
      end
      %w[src/be2e/a.ts com.acme.UserTest tests/unit/a.ts].each do |path|
        expect(described_class.e2e?(path:)).to be(false), path
      end
    end
  end

  describe TestManagement::Automation::Reference::Context do
    shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
    shared_let(:shop) { create(:tm_ci_connection, project:, repository: "my-org/shop") }
    shared_let(:api) { create(:tm_ci_connection, project:, repository: "my-org/api-service", reference_name: "api") }

    it "lists the most specific candidates first" do
      context = described_class.new(project:, connection: shop, format: "junit_xml")

      expect(context.candidates("tests/a.ts#x")).to eq(["shop:tests/a.ts#x", "shop/e2e:tests/a.ts#x", "tests/a.ts#x"])
      expect(context.candidates("api:A#b").first).to eq("api:A#b")
    end

    it "uses the last segment of ci.repository without a connection" do
      options = TestManagement::Automation::Options.new("ci" => { "repository" => "acme/mobile.git" })
      context = described_class.new(project:, options:)

      expect(context.name).to eq("mobile")
    end
  end
end
