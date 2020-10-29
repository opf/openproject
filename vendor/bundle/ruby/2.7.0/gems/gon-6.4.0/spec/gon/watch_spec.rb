describe Gon::Watch do

  let(:controller) { ActionController::Base.new }
  let(:request) { ActionDispatch::Request.new({}) }

  before :each do
    controller.request = request
    controller.params = {}
    env = {}
    env['ORIGINAL_FULLPATH'] = '/foo'
    env['REQUEST_METHOD'] = 'GET'

    Gon::Watch.clear
    Gon.send(:current_gon).instance_variable_set(:@env, env)
    Gon.send(:current_gon).env['action_controller.instance'] = controller
    Gon.clear
  end

  it 'should add variables to Gon#all_variables hash' do
    Gon.a = 1
    Gon.watch.b = 2
    expect(Gon.all_variables).to eq({ 'a' => 1, 'b' => 2 })
  end

  describe '#all_variables' do

    it 'should generate array with current request url, method type and variable names' do
      Gon.watch.a = 1
      expect(Gon.watch.all_variables).to eq({ 'a' => { 'url' => '/foo', 'method' => 'GET', 'name' => 'a' } })
    end

  end

  describe '#render' do

    it 'should render function with variables in gon namespace' do
      Gon.watch.a = 1
      expect(Gon.watch.render).to match(/gon\.watch\s=/)
      expect(Gon.watch.render).to match(/gon\.watchedVariables/)
    end

  end

  describe 'Render concrete variable' do
    before do
      env = Gon.send(:current_gon).env
      env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'

      allow(controller).to receive_messages(request: ActionDispatch::Request.new(env))
      Gon.send(:current_gon).env['action_controller.instance'] = controller
    end

    context 'when request variable is json safe content' do
      before do
        allow(controller).to receive_messages(params: {
          gon_return_variable: true,
          gon_watched_variable: 'safety'})
      end

      it 'should return value of variable if called right request' do
        expect(controller).to receive(:render).with(json: '12345')
        Gon.watch.safety = 12345
      end
    end

    context 'when request variable is json unsafe content' do
      let(:expected) { %Q{"\\u003cscript\\u003e'\\"\\u003c/script\\u003e&#x2028;Dangerous"} }

      before do
        allow(controller).to receive_messages(params: {
          gon_return_variable: true,
          gon_watched_variable: 'danger'})
      end

      it 'should return value of variable if called right request' do
        expect(controller).to receive(:render).with(json: expected)
        Gon.watch.danger = %Q{<script>'"</script>\u2028Dangerous}
      end
    end
  end
end
