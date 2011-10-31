#-- encoding: UTF-8
require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../init'

class PaginationHelperTest < Test::Unit::TestCase
  include ActionController::Pagination
  include ActionView::Helpers::PaginationHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper

  def setup
    @controller = Class.new do
      attr_accessor :url, :request
      def url_for(options, *parameters_for_method_reference)
        url
      end
    end
    @controller = @controller.new
    @controller.url = "http://www.example.com"
  end

  def test_pagination_links
    total, per_page, page = 30, 10, 1
    output = pagination_links Paginator.new(@controller, total, per_page, page)
    assert_equal "1 <a href=\"http://www.example.com\">2</a> <a href=\"http://www.example.com\">3</a> ", output
  end

  def test_pagination_links_with_prefix
    total, per_page, page = 30, 10, 1
    output = pagination_links Paginator.new(@controller, total, per_page, page), :prefix => 'Newer '
    assert_equal "Newer 1 <a href=\"http://www.example.com\">2</a> <a href=\"http://www.example.com\">3</a> ", output
  end

  def test_pagination_links_with_suffix
    total, per_page, page = 30, 10, 1
    output = pagination_links Paginator.new(@controller, total, per_page, page), :suffix => 'Older'
    assert_equal "1 <a href=\"http://www.example.com\">2</a> <a href=\"http://www.example.com\">3</a> Older", output
  end
end
