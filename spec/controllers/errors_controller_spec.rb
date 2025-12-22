RSpec.describe ErrorsController do
  describe '#show' do
    let(:error_response) do
      request.env['action_dispatch.exception'] = exception
      Rails.application.config.exceptions_app.call(request.env)
    end

    context 'with 404 error' do
      let(:exception) { ActionController::RoutingError.new('Not Found') }

      it 'returns 404 status' do
        expect(error_response[0]).to eq(404)
      end
    end

    context 'with 500 error' do
      let(:exception) { StandardError.new('Internal Server Error') }

      it 'returns 500 status' do
        expect(error_response[0]).to eq(500)
      end
    end
  end
end
