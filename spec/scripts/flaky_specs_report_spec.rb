# frozen_string_literal: true

require "rspec_helper"
require "fileutils"
require "json"
require "open3"
require "tmpdir"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "script/flaky_specs_report" do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:script) { root.join("script/flaky_specs_report") }
  let(:stub_dir) { Pathname(Dir.mktmpdir("flaky_specs_report")) }
  let(:bin_dir) { stub_dir.join("bin") }
  let(:gh_log_path) { stub_dir.join("gh.log") }

  before do
    bin_dir.mkpath
    gh_log_path.write("")
    write_gh_stub
  end

  after do
    FileUtils.remove_entry(stub_dir) if stub_dir.exist?
  end

  it "counts each visible flaky spec once in raw mode" do
    write_comments(
      flaky_comment(
        pull_request_number: 24011,
        specs: [
          "./spec/features/projects/lists/filters_spec.rb[1:6:1]",
          "./modules/gantt/spec/features/timeline/timeline_dates_spec.rb[1:2:1]"
        ]
      )
    )

    result = run_report("24", "opf/openproject")

    expect(result.status).to be_success
    expect(result.stdout).to include("   1  ./spec/features/projects/lists/filters_spec.rb[1:6:1]")
    expect(result.stdout).to include("   1  ./modules/gantt/spec/features/timeline/timeline_dates_spec.rb[1:2:1]")
    expect(result.stdout.scan("filters_spec.rb[1:6:1]").size).to eq(1)
    expect(gh_log).not_to include("branches/dev")
    expect(gh_log).not_to include("compare/")
  end

  it "exits successfully when there are no flaky comments" do
    write_comments

    result = run_report("24", "opf/openproject")

    expect(result.status).to be_success
    expect(result.stdout).to include("No flaky specs found")
  end

  it "stays cheap by default, skipping PR and compare lookups" do
    write_comments(
      flaky_comment(
        pull_request_number: 24011,
        specs: ["./spec/features/projects/lists/filters_spec.rb[1:6:1]"]
      )
    )
    write_branch_dev("d" * 40)

    result = run_report("24", "opf/openproject")

    expect(result.status).to be_success
    expect(gh_log).not_to include("branches/dev")
    expect(gh_log).not_to include("pulls/")
    expect(gh_log).not_to include("compare/")
  end

  it "uses exact commit metadata when present and current PR head as an approximate fallback" do
    fresh_sha = "f" * 40
    stale_sha = "a" * 40

    write_comments(
      flaky_comment(
        pull_request_number: 24011,
        commit: fresh_sha,
        specs: ["./spec/features/current_spec.rb[1:1]"]
      ),
      flaky_comment(
        pull_request_number: 24012,
        specs: ["./spec/features/legacy_spec.rb[1:1]"]
      )
    )
    write_branch_dev("d" * 40)
    write_pull(24012, stale_sha)
    write_compare(fresh_sha, behind_by: 0)
    write_compare(stale_sha, behind_by: 451)

    result = run_report("--freshness-commits", "50", "24", "opf/openproject")

    expect(result.status).to be_success
    expect(result.stdout).to match(/\s+1\s+1\s+1\s+0\s+0\s+0\s+\.\/spec\/features\/current_spec\.rb\[1:1\]/)
    expect(result.stdout).to match(/\s+0\s+1\s+0\s+1\s+0\s+1\s+\.\/spec\/features\/legacy_spec\.rb\[1:1\]/)
    expect(gh_log).to include("branches/dev")
    expect(gh_log).to include("pulls/24012")
    expect(gh_log).not_to include("pulls/24011")
  end

  it "shows unknown occurrences without adding them to the default ranking count" do
    write_comments(
      flaky_comment(
        pull_request_number: 24013,
        specs: ["./spec/features/unknown_spec.rb[1:1]"]
      )
    )
    write_branch_dev("d" * 40)

    result = run_report("--freshness", "24", "opf/openproject")

    expect(result.status).to be_success
    expect(result.stdout).to match(/\s+0\s+1\s+0\s+0\s+1\s+0\s+\.\/spec\/features\/unknown_spec\.rb\[1:1\]/)
  end

  it "exits successfully in freshness mode when there are no flaky comments" do
    write_comments

    result = run_report("--freshness", "24", "opf/openproject")

    expect(result.status).to be_success
    expect(result.stdout).to include("No flaky specs found")
    expect(gh_log).not_to include("branches/dev")
  end

  it "can rank by total count when stale occurrences are included" do
    stale_sha = "b" * 40

    write_comments(
      flaky_comment(
        pull_request_number: 24014,
        commit: stale_sha,
        specs: ["./spec/features/stale_spec.rb[1:1]"]
      )
    )
    write_branch_dev("d" * 40)
    write_compare(stale_sha, behind_by: 100)

    result = run_report("--include-stale", "24", "opf/openproject")

    expect(result.status).to be_success
    expect(result.stdout).to match(/\s+1\s+1\s+0\s+1\s+0\s+0\s+\.\/spec\/features\/stale_spec\.rb\[1:1\]/)
  end

  it "documents commit metadata in the flaky comment template" do
    template = root.join(".github/flaky-spec-copilot-comment.md").read

    expect(template).to include("<!-- openproject-flaky-specs:")
    expect(template).to include("commit=${GITHUB_SHA}")
    expect(template).to include("run_url=${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}")
    expect(template).to include("run_id=${GITHUB_RUN_ID}")
    expect(template.index("<!-- openproject-flaky-specs:")).to be < template.index("${SPECS}")
  end

  it "passes GitHub Actions metadata variables through envsubst" do
    workflow = root.join(".github/workflows/test-core.yml").read

    expect(workflow).to include("$SPECS $PR_NUMBER $PR_AUTHOR $GITHUB_SHA $GITHUB_SERVER_URL $GITHUB_REPOSITORY $GITHUB_RUN_ID")
  end

  def run_report(*)
    stdout, stderr, status = Open3.capture3(
      env,
      script.to_s,
      *,
      chdir: root.to_s
    )

    Data.define(:stdout, :stderr, :status).new(stdout:, stderr:, status:)
  end

  def env
    {
      "PATH" => "#{bin_dir}:#{ENV.fetch('PATH')}",
      "GH_STUB_DIR" => stub_dir.to_s,
      "GH_STUB_LOG" => gh_log_path.to_s
    }
  end

  def write_comments(*comments)
    stub_dir.join("issues_comments.json").write(JSON.pretty_generate(comments))
  end

  def write_branch_dev(sha)
    stub_dir.join("branch_dev.json").write(JSON.generate({ "commit" => { "sha" => sha } }))
  end

  def write_pull(pull_request_number, sha)
    stub_dir.join("pull_#{pull_request_number}.json").write(JSON.generate({ "head" => { "sha" => sha } }))
  end

  def write_compare(sha, behind_by:)
    stub_dir.join("compare_#{sha}.json").write(JSON.generate({ "behind_by" => behind_by }))
  end

  def flaky_comment(pull_request_number:, specs:, commit: nil, run_id: 9001)
    {
      "id" => pull_request_number * 1000,
      "issue_url" => "https://api.github.com/repos/opf/openproject/issues/#{pull_request_number}",
      "body" => flaky_body(pull_request_number:, specs:, commit:, run_id:)
    }
  end

  def flaky_body(pull_request_number:, specs:, commit:, run_id:)
    metadata = if commit
                 <<~MARKDOWN
                   <!-- openproject-flaky-specs:
                   commit=#{commit}
                   run_url=https://github.com/opf/openproject/actions/runs/#{run_id}
                   run_id=#{run_id}
                   -->
                 MARKDOWN
               else
                 ""
               end

    spec_lines = specs.map { |spec| "- `rspec #{spec}`" }.join("\n")

    <<~MARKDOWN
      > [!WARNING]
      > Flaky specs

      #{metadata}
      #{spec_lines}

      <details>
      <summary>Ask Copilot to investigate</summary>

      ```
      @copilot The following spec(s) are flaky in CI (first seen on PR ##{pull_request_number}, linked for reference only):

      #{spec_lines}
      ```

      </details>
    MARKDOWN
  end

  def write_gh_stub
    bin_dir.join("gh").write(<<~'RUBY')
      #!/usr/bin/env ruby
      # frozen_string_literal: true

      require "json"

      stub_dir = ENV.fetch("GH_STUB_DIR")
      File.open(ENV.fetch("GH_STUB_LOG"), "a") { |file| file.puts(ARGV.join(" ")) }

      path = ARGV.find { |arg| arg.start_with?("repos/") }
      abort "unexpected gh call: #{ARGV.join(' ')}" unless path

      case path
      when %r{\Arepos/opf/openproject/issues/comments\z}
        print File.read(File.join(stub_dir, "issues_comments.json"))
      when %r{\Arepos/opf/openproject/branches/dev\z}
        print File.read(File.join(stub_dir, "branch_dev.json"))
      when %r{\Arepos/opf/openproject/pulls/(\d+)\z}
        print File.read(File.join(stub_dir, "pull_#{$1}.json"))
      when %r{\Arepos/opf/openproject/compare/(.+)\.\.\.(.+)\z}
        sha = Regexp.last_match(2)
        print File.read(File.join(stub_dir, "compare_#{sha}.json"))
      else
        abort "unexpected gh api path: #{path}"
      end
    RUBY
    bin_dir.join("gh").chmod(0o755)
  end

  def gh_log
    gh_log_path.read
  end
end
# rubocop:enable RSpec/DescribeClass
