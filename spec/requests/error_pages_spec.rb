# frozen_string_literal: true

require 'rails_helper'

# Body-content assertions live in spec/components/arcdex/errors_component_spec.rb.
# This spec verifies that a non-existent route returns 404.
RSpec.describe 'Error pages' do
  describe '404 page' do
    it 'returns a 404 status for an unknown path' do
      get '/this-page-does-not-exist'
      expect(response).to have_http_status(:not_found)
    end
  end
end
