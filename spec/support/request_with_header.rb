RSpec.configure do |c|
  ##
  # Session-based API authentication requires the X-requested-with header to be present.
  c.before(:each, type: :request) do |ex|
    unless ex.metadata[:skip_xhr_header]
      header("X-Requested-With", "XMLHttpRequest")
    end
  end

  c.before(:each, content_type: :json, type: :request) do |_ex|
    header("Content-Type", "application/json")
  end
end
