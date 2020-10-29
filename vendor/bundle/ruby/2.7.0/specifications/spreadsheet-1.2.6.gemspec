# -*- encoding: utf-8 -*-
# stub: spreadsheet 1.2.6 ruby lib

Gem::Specification.new do |s|
  s.name = "spreadsheet".freeze
  s.version = "1.2.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hannes F. Wyss, Masaomi Hatakeyama, Zeno R.R. Davatz".freeze]
  s.date = "2020-01-22"
  s.description = "The Spreadsheet Library is designed to read and write Spreadsheet Documents.\nAs of version 0.6.0, only Microsoft Excel compatible spreadsheets are\nsupported. Spreadsheet is a combination/complete rewrite of the\nSpreadsheet::Excel Library by Daniel J. Berger and the ParseExcel Library by\nHannes Wyss. Spreadsheet can read, write and modify Spreadsheet Documents.".freeze
  s.email = "zdavatz@ywesee.com".freeze
  s.executables = ["xlsopcodes".freeze]
  s.extra_rdoc_files = ["GUIDE.md".freeze, "History.md".freeze, "LICENSE.txt".freeze, "Manifest.txt".freeze, "README.md".freeze]
  s.files = ["GUIDE.md".freeze, "History.md".freeze, "LICENSE.txt".freeze, "Manifest.txt".freeze, "README.md".freeze, "bin/xlsopcodes".freeze]
  s.homepage = "https://github.com/zdavatz/spreadsheet".freeze
  s.licenses = ["GPL-3.0".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "The Spreadsheet Library is designed to read and write Spreadsheet Documents".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<ruby-ole>.freeze, [">= 1.0"])
    s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
    s.add_development_dependency(%q<hoe>.freeze, ["~> 3.17"])
  else
    s.add_dependency(%q<ruby-ole>.freeze, [">= 1.0"])
    s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.17"])
  end
end
