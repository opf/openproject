# frozen_string_literal: true

require "spec_helper"

RSpec.describe "TestManagement::Automation options and status mapping" do # rubocop:disable RSpec/DescribeClass
  let(:mapper_class) { TestManagement::Automation::StatusMapper }
  let(:options_class) { TestManagement::Automation::Options }

  describe TestManagement::Automation::StatusMapper do
    it "maps the usual statuses of Playwright, JUnit and the native format" do
      mapper = mapper_class.new

      expect(%w[passed expected failed timedOut interrupted skipped flaky].map { |s| mapper.call(s) })
        .to eq(%w[passed passed failed failed blocked skipped passed])
    end

    it "applies skippedAs, flakyAs and the statusMap" do
      mapper = mapper_class.new(skipped_as: "ignore", flaky_as: "retest", status_map: { "broken" => "blocked" })

      expect(mapper.call("skipped")).to be_nil
      expect(mapper.call("flaky")).to eq("retest")
      expect(mapper.call("Broken")).to eq("blocked")
      expect { mapper.call("exploded") }.to raise_error(KeyError)
    end
  end

  describe TestManagement::Automation::Options do
    it "accepts camelCase and snake_case keys and keeps only known CI keys" do
      options = options_class.new("closeRun" => "true", "case_matcher" => "reference",
                                  "ci" => { "runUrl" => "https://ci.example.com/1", "token" => "secret" },
                                  "workPackageIds" => ["#5", "7", "x"])

      expect(options).to be_close_run
      expect(options.case_matcher).to eq("reference")
      expect(options.ci).to eq("runUrl" => "https://ci.example.com/1")
      expect(options.work_package_ids).to eq([5, 7])
    end

    it "has defaults" do
      options = options_class.new

      expect(options.format).to eq("auto")
      expect(options.skipped_as).to eq("skipped")
      expect(options).to be_update_references
      expect(options).not_to be_close_run
    end

    it "rejects invalid values with :unprocessable" do
      expect { options_class.new("caseMatcher" => "magic") }
        .to raise_error(TestManagement::Automation::Error) { |e| expect(e.code).to eq(:unprocessable) }
      expect { options_class.new("statusMap" => { "x" => "nope" }) }
        .to raise_error(TestManagement::Automation::Error) { |e| expect(e.code).to eq(:unprocessable) }
    end

    it "limits attachmentPaths to the attachment maximum" do
      options = options_class.new("attachmentPaths" => Array.new(250) { |i| "f#{i}.png" })

      expect(options.attachment_paths.size).to eq(TestManagement::Automation::AttachmentWriter::MAX_FILES)
    end
  end
end
