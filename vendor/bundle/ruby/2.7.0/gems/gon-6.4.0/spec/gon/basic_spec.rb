describe Gon do

  before(:each) do
    Gon.clear
  end

  describe '#all_variables' do

    it 'returns all variables in hash' do
      Gon.a = 1
      Gon.b = 2
      Gon.c = Gon.a + Gon.b
      expect(Gon.c).to eq(3)
      expect(Gon.all_variables).to eq({ 'a' => 1, 'b' => 2, 'c' => 3 })
    end

    it 'supports all data types' do
      Gon.int          = 1
      Gon.float        = 1.1
      Gon.string       = 'string'
      Gon.symbol       = :symbol
      Gon.array        = [1, 'string']
      Gon.hash_var     = { :a => 1, :b => '2' }
      Gon.hash_w_array = { :a => [2, 3] }
      Gon.klass        = Hash
    end

    it 'can be filled with dynamic named variables' do
      check = {}
      3.times do |i|
        Gon.set_variable("variable#{i}", i)
        check["variable#{i}"] = i
      end

      expect(Gon.all_variables).to eq(check)
    end

    it 'can set and get variable with dynamic name' do
      var_name = "variable#{rand}"

      Gon.set_variable(var_name, 1)
      expect(Gon.get_variable(var_name)).to eq(1)
    end

    it 'can be support new push syntax' do
      Gon.push({ :int => 1, :string => 'string' })
      expect(Gon.all_variables).to eq({ 'int' => 1, 'string' => 'string' })
    end

    it 'push with wrong object' do
      expect {
        Gon.push(String.new('string object'))
      }.to raise_error('Object must have each_pair method')
    end

    describe "#merge_variable" do
      it 'deep merges the same key' do
        Gon.merge_variable(:foo, { bar: { tar: 12 }, car: 23 })
        Gon.merge_variable(:foo, { bar: { dar: 21 }, car: 12 })
        expect(Gon.get_variable(:foo)).to  eq(bar: { tar: 12, dar: 21 }, car: 12)
      end

      it 'merges on push with a flag' do
        Gon.push(foo: { bar: 1 })
        Gon.push({ foo: { tar: 1 } }, :merge)
        expect(Gon.get_variable("foo")).to eq(bar: 1, tar: 1)
      end

      context 'overrides key' do
        specify "the previous value wasn't hash" do
          Gon.merge_variable(:foo, 2)
          Gon.merge_variable(:foo, { a: 1 })
          expect(Gon.get_variable(:foo)).to eq(a: 1)
        end

        specify "the new value isn't a hash" do
          Gon.merge_variable(:foo, { a: 1 })
          Gon.merge_variable(:foo, 2)
          expect(Gon.get_variable(:foo)).to eq(2)
        end
      end
    end

  end

  describe '#include_gon' do

    before(:each) do
      Gon::Request.
        instance_variable_set(:@request_id, request.object_id)
      expect(ActionView::Base.instance_methods).to include(:include_gon)
      @base = ActionView::Base.new
      @base.request = request
    end

    it 'outputs correct js with an integer' do
      Gon.int = 1
      expect(@base.include_gon).to eq(wrap_script(
                                'window.gon={};' +
                                'gon.int=1;'))
    end

    it 'outputs correct js with a string' do
      Gon.str = %q(a'b"c)
      expect(@base.include_gon).to eq(wrap_script(
                                'window.gon={};' +
                                %q(gon.str="a'b\"c";))
      )
    end

    it 'outputs correct js with a script string' do
      Gon.str = %q(</script><script>alert('!')</script>)
      escaped_str = "\\u003c/script\\u003e\\u003cscript\\u003ealert('!')\\u003c/script\\u003e"
      expect(@base.include_gon).to eq(wrap_script(
                                'window.gon={};' +
                                %Q(gon.str="#{escaped_str}";))
      )
    end

    it 'outputs correct js with an integer and type' do
      Gon.int = 1
      expect(@base.include_gon(type: true)).to eq('<script type="text/javascript">' +
                                    "\n//<![CDATA[\n" +
                                    'window.gon={};' +
                                    'gon.int=1;' +
                                    "\n//]]>\n" +
                                  '</script>')
    end

    it 'outputs correct js with an integer, camel-case and namespace' do
      Gon.int_cased = 1
      expect(@base.include_gon(camel_case: true, namespace: 'camel_cased')).to eq(
                                  wrap_script('window.camel_cased={};' +
                                    'camel_cased.intCased=1;')
      )
    end

    it 'outputs correct js with camel_depth = :recursive' do
      Gon.test_hash = { test_depth_one: { test_depth_two: 1 } }
      expect(@base.include_gon(camel_case: true, camel_depth: :recursive)).to eq(
                                  wrap_script('window.gon={};' +
                                    'gon.testHash={"testDepthOne":{"testDepthTwo":1}};')
      )
    end

    it 'outputs correct js with camel_depth = 2' do
      Gon.test_hash = { test_depth_one: { test_depth_two: 1 } }
      expect(@base.include_gon(camel_case: true, camel_depth: 2)).to eq(
                                  wrap_script('window.gon={};' +
                                    'gon.testHash={"testDepthOne":{"test_depth_two":1}};')
      )
    end

    it 'outputs correct js for an array with camel_depth = :recursive' do
      Gon.test_hash = { test_depth_one: [{ test_depth_two: 1 }, { test_depth_two: 2 }] }
      expect(@base.include_gon(camel_case: true, camel_depth: :recursive)).to eq( \
                                  wrap_script('window.gon={};' +
                                    'gon.testHash={"testDepthOne":[{"testDepthTwo":1},{"testDepthTwo":2}]};')
      )
    end

    it 'outputs correct key with camel_case option set alternately ' do
      Gon.test_hash = 1
      @base.include_gon(camel_case: true)

      expect(@base.include_gon(camel_case: false)).to eq(
                                 wrap_script('window.gon={};' +
                                   'gon.test_hash=1;')
      )
    end

    it 'outputs correct js with an integer and without tag' do
      Gon.int = 1
      expect(@base.include_gon(need_tag: false)).to eq( \
                                  'window.gon={};' +
                                  'gon.int=1;'
      )
    end

    it 'outputs correct js without variables, without tag and gon init if before there was data' do
      Gon::Request.
        instance_variable_set(:@request_id, 123)
      Gon::Request.instance_variable_set(:@request_env, { 'gon' => { :a => 1 } })
      expect(@base.include_gon(need_tag: false, init: true)).to eq( \
                                  'window.gon={};'
      )
    end

    it 'outputs correct js without variables, without tag and gon init' do
      expect(@base.include_gon(need_tag: false, init: true)).to eq( \
                                  'window.gon={};'
      )
    end

    it 'outputs correct js without variables, without tag, gon init and an integer' do
      Gon.int = 1
      expect(@base.include_gon(need_tag: false, init: true)).to eq( \
                                  'window.gon={};' +
                                  'gon.int=1;'
      )
    end

    it 'outputs correct js without cdata, without type, gon init and an integer' do
      Gon.int = 1
      expect(@base.include_gon(cdata: false, type: false)).to eq(
                                  wrap_script(
                                    "\n" +
                                    'window.gon={};' +
                                    'gon.int=1;' +
                                    "\n", false)
      )
    end

    it 'outputs correct js with type text/javascript' do
      expect(@base.include_gon(need_type: true, init: true)).to eq(wrap_script('window.gon={};'))
    end

    it 'outputs correct js with namespace check' do
      expect(@base.include_gon(namespace_check: true)).to eq(wrap_script('window.gon=window.gon||{};'))
    end

    it 'outputs correct js without namespace check' do
      expect(@base.include_gon(namespace_check: false)).to eq(wrap_script('window.gon={};'))
    end

    context "without a current_gon instance" do

      before(:each) do
        RequestStore.store[:gon] = nil
        allow(Gon).to receive(:current_gon).and_return(nil)
      end

      it "does not raise an exception" do
        expect { @base.include_gon }.to_not raise_error
      end

      it 'outputs correct js' do
        expect(@base.include_gon).to eq("")
      end

      it 'outputs correct js with init' do
        expect(@base.include_gon(init: true)).to eq(wrap_script('window.gon={};'))
      end

    end

  end

  describe '#include_gon_amd' do

    before(:each) do
      Gon::Request.
        instance_variable_set(:@request_id, request.object_id)
      @base = ActionView::Base.new
      @base.request = request
    end

    it 'is included in ActionView::Base as a helper' do
      expect(ActionView::Base.instance_methods).to include(:include_gon_amd)
    end

    it 'outputs correct js without variables' do
      expect(@base.include_gon_amd).to eq( wrap_script( \
                                    'define(\'gon\',[],function(){'+
                                    'var gon={};return gon;'+
                                    '});')
      )
    end

    it 'outputs correct js with an integer' do
      Gon.int = 1

      expect(@base.include_gon_amd).to eq( wrap_script(
                                    'define(\'gon\',[],function(){'+
                                    'var gon={};gon[\'int\']=1;return gon;'+
                                    '});')
      )
    end

    it 'outputs correct module name when given a namespace' do
      expect(@base.include_gon_amd(namespace: 'data')).to eq(wrap_script(
                                    'define(\'data\',[],function(){'+
                                    'var gon={};return gon;'+
                                    '});')
      )
    end
  end

  it 'returns exception if try to set public method as variable' do
    expect { Gon.all_variables = 123 }.to raise_error(RuntimeError)
    expect { Gon.rabl = 123 }.to raise_error(RuntimeError)
  end

  describe '#check_for_rabl_and_jbuilder' do

    let(:controller) { ActionController::Base.new }

    it 'should be able to handle constants array (symbols)' do
      allow(Gon).to receive(:constants) { Gon.constants }
      expect { Gon.rabl :template => 'spec/test_data/sample.rabl', :controller => controller }.not_to raise_error
      expect { Gon.jbuilder :template => 'spec/test_data/sample.json.jbuilder', :controller => controller }.not_to raise_error
    end
  end
end
