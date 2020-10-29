require 'rails/railtie'
# We don't require rails for specs, but jbuilder works only in rails.
# And it checks version of rails. I've decided to configure jbuilder for rails v4
module Rails
  module VERSION
    MAJOR = 4
  end

  def self.version
    '4.2.0'
  end
end

require 'gon'

require 'jbuilder'

RSpec.configure do |config|
  config.before(:each) do
    RequestStore.store[:gon] = Gon::Request.new({})
    @request = RequestStore.store[:gon]
    allow(Gon).to receive(:current_gon).and_return(@request)
  end
end

def request
  @request ||= double 'request', :env => {}
end

def wrap_script(content, cdata=true)
  script = "<script>"
  script << "\n//<![CDATA[\n" if cdata
  script << content
  script << "\n//]]>\n" if cdata
  script << '</script>'
end
