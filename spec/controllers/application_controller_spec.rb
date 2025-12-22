RSpec.describe ApplicationController do
  describe '#render404' do
    it 'raises a RoutingError' do
      expect {
        controller.render404
      }.to raise_error(ActionController::RoutingError, 'Not Found')
    end
  end
end
