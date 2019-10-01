# Fail if jasmine specs contain fdescribe or fit
fail("jasmine fdescribe left in tests") if `grep --include '*.spec.ts' -rP 'fdescribe|fit' frontend/src/`.length > 1

# Search for modified components not being made OnPush
git.modified_files
    .select { |path| path.include?('frontend') && path.end_with?('.ts') }
    .each do |path|
  next unless File.readable?(path)

  lines = File.readlines (path)

  # Ignore non component files
  component_line = lines.grep(/@Component/)[0]
  next unless component_line

  # Check for missing onPush
  unless lines.grep(/changeDetection:\s+ChangeDetectionStrategy.OnPush/).length > 0
    warn(
        "Please use `ChangeDetectionStrategy.OnPush` for this component",
        file: path,
        line: lines.index(component_line) || 0
        )
  end
end
