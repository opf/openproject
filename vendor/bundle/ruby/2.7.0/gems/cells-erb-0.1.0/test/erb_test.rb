require 'test_helper'

class ErbTest < MiniTest::Spec
  let (:controller) { ApplicationController.new.tap { |ctl| ctl.send("request=", ActionDispatch::Request.new({})) } }
  let (:song_cell) { SongCell.new(controller) }

  # render in render
  it { song_cell.(:render_in_render).must_equal "<b>Questions: Yes!</b>" }

  # URL helpers work in cell instance.
  # -- this is actually covered well enough in cells, and is unrelated to ERB.
  # it { song_cell.songs_path.must_equal "/songs" }

  # content_tag { }
  it { song_cell.(:with_content_tag).must_equal "<div>Beachparty</div>" }

  # content_tag { content_tag { } }
  it do song_cell.(:with_content_tag_and_content_tag).must_equal %{<span>    Title:
    <div>        Still Knee Deep
    </div></span>}
  end

  # describe "benchmarking" do
  #   it do
  #     require "benchmark"
  #     t = Benchmark.measure do
  #       10000.times { |i| song_cell.(:with_content_tag_and_content_tag) }
  #     end

  #     puts "@@@@@ #{t}"
  #   end
  # end

  # form_tag { content_tag { } }
  it do
    form_tag = "<form action=\"/erubis/is/horribly/outdated\" accept-charset=\"UTF-8\" method=\"post\"><input name=\"utf8\" type=\"hidden\" value=\"&#x2713;\" />"
    form_tag = "<form accept-charset=\"UTF-8\" action=\"/erubis/is/horribly/outdated\" method=\"post\"><div style=\"margin:0;padding:0;display:inline\"><input name=\"utf8\" type=\"hidden\" value=\"&#x2713;\" /></div>" if ActionPack::VERSION::MAJOR == 3

    form_with_body_tag = "<form url=\"/rails/escapes/too/much\" method=\"post\"><input name=\"utf8\" type=\"hidden\" value=\"&#x2713;\" /><input type=\"button\"/></form>"
    form_with_body_tag = "<form method=\"post\" url=\"/rails/escapes/too/much\"><div style=\"margin:0;padding:0;display:inline\"><input name=\"utf8\" type=\"hidden\" value=\"&#x2713;\" /></div><input type=\"button\"/></form>" if ActionPack::VERSION::MAJOR == 3

    form_for_tag = "<form class=\"new_open\" id=\"new_open\" action=\"/\" accept-charset=\"UTF-8\" method=\"post\"><input name=\"utf8\" type=\"hidden\" value=\"&#x2713;\" /><input type=\"text\" name=\"open[id]\" id=\"open_id\" /></form>"
    form_for_tag = "<form accept-charset=\"UTF-8\" action=\"/\" class=\"new_open\" id=\"new_open\" method=\"post\"><div style=\"margin:0;padding:0;display:inline\"><input name=\"utf8\" type=\"hidden\" value=\"&#x2713;\" /></div>
  <input id=\"open_id\" name=\"open[id]\" size=\"30\" type=\"text\" />
</form>" if ActionPack::VERSION::MAJOR == 3

    song_cell.(:with_form_tag_and_content_tag).must_equal %{Word.

#{form_tag}<a href=\"/rails/sucks\">    hallo
    <div class="row">
      Cool
    </div>
  </a><ul data-x="{&quot;a&quot;:&quot;1&quot;}">   Hallo
  </ul></form>Weiter!

  Bonjour!
  <a href=\"/coffee\">Coffee?</a>  <b>Yes please!</b>
  <script>oui!</script><a href=\"/1\">1</a>+<a href=\"/2\">2</a><b>No current page!<b>#{form_with_body_tag}#{form_for_tag}<div><p>Concat!</p>Whoo</div>}
  end

  it do
    # puts ErbseCell.new.()
    ErbseCell.new.().must_equal %{bla
<h1>Welcome!</h1>

ErbseCell  invoke!
  !unless invoke, #not!
line
  captured
}
  end
end

# start with content_tag and block (or capture) and find out how sinatra handles that. goal is NOT to use those hacks in haml's action_view_extensions.
