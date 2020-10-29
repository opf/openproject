# -*- ruby -*-

$: << File.expand_path("./lib", File.dirname(__FILE__))

require 'rubygems'
require 'bundler'

require 'hoe'
require './lib/spreadsheet.rb'

ENV['RDOCOPT'] = '-c utf8'

Hoe.plugin :git

Hoe.spec('spreadsheet') do |p|
  p.developer('Hannes F. Wyss, Masaomi Hatakeyama, Zeno R.R. Davatz','hannes.wyss@gmail.com, mhatakeyama@ywesee.com, zdavatz@ywesee.com')
   p.remote_rdoc_dir = 'spreadsheet'
   p.extra_deps << ['ruby-ole', '>=1.0']
   p.email = "zdavatz@ywesee.com"
   p.urls = ['https://github.com/zdavatz/spreadsheet']
   p.licenses = ['GPL-3.0']
end

# vim: syntax=Ruby
