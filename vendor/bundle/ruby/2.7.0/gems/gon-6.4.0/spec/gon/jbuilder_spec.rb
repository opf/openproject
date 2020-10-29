describe Gon do

  describe '.jbuilder' do
    context 'render jbuilder templates' do

      before do
        Gon.clear
        controller.instance_variable_set('@objects', objects)
      end

      let(:controller) { ActionController::Base.new }
      let(:objects) { [1, 2] }

      it 'render json from jbuilder template' do
        Gon.jbuilder :template => 'spec/test_data/sample.json.jbuilder', :controller => controller
        expect(Gon.objects.length).to eq(2)
      end

      it 'render json from jbuilder template with locals' do
        Gon.jbuilder :template => 'spec/test_data/sample_with_locals.json.jbuilder',
                     :controller => controller,
                     :locals => { :some_local => 1234, :some_complex_local => OpenStruct.new(:id => 1234) }
        expect(Gon.some_local).to eq(1234)
        expect(Gon.some_complex_local_id).to eq(1234)
      end

      it 'render json from jbuilder template with locals' do
        Gon.jbuilder :template => 'spec/test_data/sample_with_helpers.json.jbuilder', :controller => controller
        expect(Gon.date).to eq('about 6 hours')
      end

      it 'render json from jbuilder template with controller methods' do
        class << controller
          def private_controller_method
            'gon test helper works'
          end
          helper_method :private_controller_method
          private :private_controller_method
        end

        Gon.jbuilder :template => 'spec/test_data/sample_with_controller_method.json.jbuilder', :controller => controller
        expect(Gon.data_from_method).to eq('gon test helper works')
      end

      it 'render json from jbuilder template with a partial' do
        controller.view_paths << 'spec/test_data'
        Gon.jbuilder :template => 'spec/test_data/sample_with_partial.json.jbuilder', :controller => controller
        expect(Gon.objects.length).to eq(2)
      end

      context 'within Rails' do
        before do
          module ::Rails
          end

          allow(Rails).to receive_message_chain("application.routes.url_helpers.instance_methods") { [:user_path] }
          controller.instance_variable_set('@user_id', 1)
        end

        after do
          Object.send(:remove_const, :Rails)
        end

        it 'includes url_helpers' do
          expect(controller).to receive(:user_path) { |id| "/users/#{id}" }
          Gon.jbuilder :template => 'spec/test_data/sample_url_helpers.json.jbuilder', :controller => controller
          expect(Gon.url).to eq '/users/1'
        end
      end

    end

  end

end
