module Helpers
  def fixture_path(filename)
    File.expand_path(File.join('spec', 'fixtures', filename))
  end

  def project_root_path(filename)
    fixture_path(File.join('project_root', filename))
  end
end
