require 'test_helper'

class HelpControllerTest < ActionController::TestCase
  test "renders wiki_syntax properly" do
    get "wiki_syntax"

    assert_select "h1", "Wiki Syntax Quick Reference"
  end

  test "renders wiki_syntax_detailed properly" do
    get "wiki_syntax_detailed"

    assert_select "h1", "Wiki Formatting"
  end
end
