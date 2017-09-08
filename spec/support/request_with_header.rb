RSpec.configure do |c|
  c.before(:each, type: :request) do |ex|
    header('X-Requested-With', 'XMLHttpRequest') unless ex.metadata[:skip_xhr_header]
  end

  c.before(:each, type: :feature) do |ex|
    unless ex.metadata[:skip_xhr_header] || ex.metadata[:js]
      page.driver.header('X-Requested-With', 'XMLHttpRequest')
    end
  end
end

