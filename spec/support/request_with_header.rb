module APISessionAuthentication
  def merge_with_header(args = {})
    # Can't get example. in here
    metadata = self.class.metadata
    headers = args.fetch(:headers) { {} }

    unless metadata[:skip_xhr_header]
      headers.merge!('X-Requested-With' => 'XMLHttpRequest')
    end

    headers
  end

  def get(path, args = {})
    args[:headers] = merge_with_header args
    super
  end

  def post(path, args = {})
    args[:headers] = merge_with_header args
    super
  end

  def put(path, args = {})
    args[:headers] = merge_with_header args
    super
  end

  def delete(path, args = {})
    args[:headers] = merge_with_header args
    super
  end

  def patch(path, args = {})
    args[:headers] = merge_with_header args
    super
  end

  def head(path, args = {})
    args[:headers] = merge_with_header args
    super
  end
end


RSpec.configure do |c|
  ##
  # Session-based API authentication requires the X-requested-with header to be present.
  # Since Integration tests of Rails do not offer adding a header to all requests as
  # Capybara or Rack::Test does, we simply extend the request helpers to do so.
  c.include APISessionAuthentication, type: :request

  c.before(:each, type: :feature) do |ex|
    unless ex.metadata[:skip_xhr_header] || ex.metadata[:js]
      page.driver.header('X-Requested-With', 'XMLHttpRequest')
    end
  end
end

