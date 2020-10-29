require "test_helper"

#ob_0 = '';;ob_0<< ( true ).to_s;ob_0 << ' '.freeze;;ob_1 =  form_for do ; ob_2='';;ob_2<< ( 1 ).to_s;;ob_2<< ( 2 ).to_s;;ob_3 =  nested do ; ob_4='';;ob_4<< ( 3 ).to_s;;ob_4<< ( 4 ).to_s;ob_4; end ;ob_2 << ob_3;ob_3; end ;ob_1 << ob_2;ob_0.to_s

class ErbseTest < Minitest::Spec
  let (:str) { %{
<%= true %>
Text
<%= form_for do %><%= 1 %><% 2 %>
  <%= nested do %>
    <%= this %>
    <a/>
  <% end %>
<% end %>}
  }

  it "what" do
    Erbse::Parser.new.(str).must_equal [:multi,
      [:static, "\n"], [:newline],
      [:dynamic, " true "],
      [:static, "\n"], [:newline],
      [:static, "Text\n"], [:newline],
      [:erb, :block, " form_for do ", [:multi,
        [:dynamic, " 1 "],
        [:code, " 2 "], 
        [:static, "\n"], [:newline],
        [:static, "  "],
        [:erb, :block, " nested do ", [:multi, 
          [:static, "\n"], [:newline],
          [:static, "    "],
          [:dynamic, " this "],
          [:static, "\n"], [:newline],
          [:static, "    <a/>\n"], [:newline],
          [:static, "  "],
          ]], 
        [:static, "\n"], [:newline]]]]
  end

  it "generates ruby" do
      code = %{_buf = []; _buf << (\"@@\".freeze); @; _buf << ( true ); _buf << (\"@@\".freeze); @; _buf << (\"Text@@\".freeze); @; _erbse_blockfilter1 =  form_for do ; _erbse_blockfilter2 = ''; _erbse_blockfilter2 << (( 1 ).to_s);  2 ; _erbse_blockfilter2 << (\"@@\".freeze); @; _erbse_blockfilter2 << (\"  \".freeze); _erbse_blockfilter3 =  nested do ; _erbse_blockfilter4 = ''; _erbse_blockfilter4 << (\"@@\".freeze); @; _erbse_blockfilter4 << (\"    \".freeze); _erbse_blockfilter4 << (( this ).to_s); _erbse_blockfilter4 << (\"@@\".freeze); @; _erbse_blockfilter4 << (\"    <a/>@@\".freeze); @; _erbse_blockfilter4 << (\"  \".freeze); _erbse_blockfilter4; end; _erbse_blockfilter2 << ((_erbse_blockfilter3).to_s); _erbse_blockfilter2 << (\"@@\".freeze); @; _erbse_blockfilter2; end; _buf << (_erbse_blockfilter1); _buf = _buf.join(\"\".freeze)}
    ruby = Erbse::Engine.new.(str).gsub("\n", "@").gsub('\n', "@@")
    # puts ruby
    ruby.must_equal code
  end

  describe "<% %>" do
    let (:str) { %{
<% 2.times do |i| %>
  <%= i+1 %>
  <% puts %>
<% end %>

<% if 1 == 1 %>
  Hello
<% end %>
}
    }
    it "what" do
      Erbse::Parser.new.(str).must_equal [:multi,
        [:static, "\n"], [:newline],
        [:block, " 2.times do |i| ", [:multi,
          [:static, "\n"], [:newline],
          [:static, "  "],
          [:dynamic, " i+1 "], 
          [:static, "\n"], [:newline], [:static, "  "],
          [:code, " puts "], 
          [:static, "\n"], [:newline]
          ]],
          [:static, "\n"], [:newline],
          [:static, "\n"], [:newline],
        [:block, " if 1 == 1 ", [:multi,
          [:static, "\n"], [:newline],
          [:static, "  Hello\n"], [:newline]]],
          [:static, "\n"], [:newline]]
    end

    it do
      ruby = Erbse::Engine.new.(str)
      ruby = ruby.gsub("\n", "@")
      # ruby.must_equal %{_buf = [];  self ;  2.times do |i| ; _buf << ( i+1 );  puts ; end; _buf = _buf.join(\"\".freeze)}
      ruby.must_equal '_buf = []; _buf << ("\n".freeze); @;  2.times do |i| ; _buf << ("\n".freeze); @; _buf << ("  ".freeze); _buf << ( i+1 ); _buf << ("\n".freeze); @; _buf << ("  ".freeze);  puts ; _buf << ("\n".freeze); @; end; _buf << ("\n".freeze); @; _buf << ("\n".freeze); @;  if 1 == 1 ; _buf << ("\n".freeze); @; _buf << ("  Hello\n".freeze); @; end; _buf << ("\n".freeze); @; _buf = _buf.join("".freeze)'
    end

    it do
      ruby = Erbse::Engine.new.(str)
      eval(ruby).must_equal "\n\n  1\n  \n\n  2\n  \n\n\n\n  Hello\n\n"
    end
  end

  describe "pure text" do
    let (:str) { %{Holla
Hi}
    }
    it { Erbse::Parser.new.(str).must_equal [:multi, [:static, "Holla\n"], [:newline], [:static, "Hi"]] }
  end

  # comments
  describe "<%# this %>" do
    let (:str) { %{Hello
<%# Ignore this %>
Hola
<%# Ignore
this %>
Hi
<% # this %>
} }

    it do
      Erbse::Parser.new.(str).must_equal [:multi, [:static, "Hello\n"], [:newline], [:static, "\n"], [:newline], [:static, "Hola\n"], [:newline], [:newline], [:static, "\n"], [:newline], [:static, "Hi\n"], [:newline], [:code, " # this "], [:static, "\n"], [:newline]]
    end

    it do
      ruby = Erbse::Engine.new.(str).gsub("\n", "@").gsub('\n', "@@")
      code = %{_buf = []; _buf << (\"Hello@@\".freeze); @; _buf << (\"@@\".freeze); @; _buf << (\"Hola@@\".freeze); @; @; _buf << (\"@@\".freeze); @; _buf << (\"Hi@@\".freeze); @;  # this ; _buf << (\"@@\".freeze); @; _buf = _buf.join(\"\".freeze)}
      ruby.must_equal code
    end

    # <%# end %>
    it { Erbse::Parser.new.(%{Yo
<%# bla do %>
<%# end %>
1}).must_equal [:multi, [:static, "Yo\n"], [:newline], [:static, "\n"], [:newline], [:static, "\n"], [:newline], [:static, "1"]] }
  end

  describe "content after last ERB tag" do
    let (:str) { %{<b><%= 1 %>bla
blubb</b>} }

    it { Erbse::Parser.new.(str).must_equal [:multi, [:static, "<b>"], [:dynamic, " 1 "], [:static, "bla\n"], [:newline], [:static, "blubb</b>"]] }
  end

  describe "<%* %>" do
    it { Erbse::Parser.new.(%{<%- 1 %>}).must_equal [:multi, [:code, " 1 "]] }
    it { Erbse::Parser.new.(%{<%% 1 %>}).must_equal [:multi, [:code, " 1 "]] }
    it { Erbse::Parser.new.(%{<%% 1 -%>}).must_equal [:multi, [:code, " 1 "]] }
  end

  describe "<% var = 1 %>" do
    let (:str) { %{<% var = 1 %><%= var %>} }
    it { eval(Erbse::Engine.new.(str)).must_equal "1" }
  end

  describe "postfix conditional in expression tag" do
    let (:str) { %{<p><%= 'test' if true %></p>} }
    it { eval(Erbse::Engine.new.(str)).must_equal "<p>test</p>" }
  end

  describe "postfix conditional in execution tag" do
    let (:str) { %{<p><% foo = 'test' if true %><%= foo %></p>} }
    it { eval(Erbse::Engine.new.(str)).must_equal "<p>test</p>" }
  end

  describe "condition in multiline expression tag" do
    let (:str) { %{<p><%= if true
                           'test'
                          end %></p>} }
    it { eval(Erbse::Engine.new.(str)).must_equal "<p>test</p>" }
  end

  describe "multiline do-end-block in expression tag" do
    let (:str) { %{<%= [1,2].map do |i|
                 i+1
               end.join %>} }
    it { eval(Erbse::Engine.new.(str)).must_equal "23" }
  end

  describe "multiline {}-block in expression tag" do
    let (:str) { %(<%= [3,1].map { |i|
                 i+1
               }.join %>) }
    it { eval(Erbse::Engine.new.(str)).must_equal "42" }
  end

  describe "<% \"string with do\" %>" do
    it { Erbse::Parser.new.(%{<% var = "do 1" %><%= var %>}).must_equal [:multi, [:code, " var = \"do 1\" "], [:dynamic, " var "]] }
    it { Erbse::Parser.new.(%{<% var = " do 1" %><%= var %>}).must_equal [:multi, [:code, " var = \" do 1\" "], [:dynamic, " var "]] }
  end

  describe "do" do
    it { Erbse::Parser.new.(%{<% form do %>1<% end %>}).must_equal [:multi, [:block, " form do ", [:multi, [:static, "1"]]]] }
    it { Erbse::Parser.new.(%{<% form do |i| %>1<% end %>}).must_equal [:multi, [:block, " form do |i| ", [:multi, [:static, "1"]]]] }
  end

  describe "quoted conditional" do
    let (:str2) { %{
  <%= form_for do %>
    <%= link_to "string", path, "v-if" => "trigger" %>
  <% end %>}
    }

    it "parses quoted conditionals correctly" do
      Erbse::Parser.new.(str2).must_equal [:multi,
        [:static, "\n"],
        [:newline],
        [:static, "  "],
        [:erb, :block, " form_for do ", [:multi,
          [:static, "\n"],
          [:newline],
          [:static, "    "],
          [:dynamic, " link_to \"string\", path, \"v-if\" => \"trigger\" "],
          [:static, "\n"],
          [:newline],
          [:static, "  "]
        ]]]
    end
  end
  
  describe "newlines" do
    let (:str2) { %{
  abc
  <%= 'foo' %>
  def}
    }

    it "puts newlines after code" do
      Erbse::Parser.new.(str2).must_equal [:multi,
        [:static, "\n"],
        [:newline],
        [:static, "  abc\n"],
        [:newline],
        [:static, "  "],
        [:dynamic, " 'foo' "],
        [:static, "\n"],
        [:newline],
        [:static, '  def'],
      ]
    end
  end

  describe "<%@ %>" do
    let (:str) { %{<%@ content = capture do %>
  Yo!
  <%= 1 %>
<% end %>} }

    it do
      ruby = Erbse::Engine.new.(str).gsub("\n", "@").gsub('\n', "@@")
      code = %{_buf = []; content = capture do ; _erbse_blockfilter1 = ''; _erbse_blockfilter1 << (\"@@\".freeze); @; _erbse_blockfilter1 << (\"  Yo!@@\".freeze); @; _erbse_blockfilter1 << (\"  \".freeze); _erbse_blockfilter1 << (( 1 ).to_s); _erbse_blockfilter1 << (\"@@\".freeze); @; _erbse_blockfilter1; end; _buf = _buf.join(\"\".freeze)}
      ruby.must_equal code
    end

    it do
      Erbse::Parser.new.(%{<%@content = capture do %><% end %>}).must_equal [:multi, [:block, "@content = capture do ", [:multi]]]
    end
  end
end
