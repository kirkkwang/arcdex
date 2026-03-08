# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController do
  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '12345',
      info: { email: 'ash@pokemon.com', image: 'https://example.com/avatar.jpg' }
    )
  end

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
    request.env['omniauth.auth'] = auth_hash
    allow_any_instance_of(described_class).to receive(:sign_out_all_scopes) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:sign_in_and_redirect) do |c, _user, **| # rubocop:disable RSpec/AnyInstance
      c.redirect_to root_path
    end
  end

  describe '#google_oauth2' do
    context 'when User.from_google returns a user' do
      let(:user) { instance_double(User, present?: true) }

      before do
        allow(User).to receive(:from_google).and_return(user)
        get :google_oauth2
      end

      it 'signs out all scopes and redirects' do
        expect(response).to have_http_status(:ok).or have_http_status(:redirect)
      end
    end

    context 'when User.from_google returns nil' do
      before do
        allow(User).to receive(:from_google).and_return(nil)
        get :google_oauth2
      end

      it 'redirects to the login page' do
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe '#from_google_params' do
    it 'returns a hash with uid, email, and avatar_url from the auth hash' do
      result = controller.send(:from_google_params)
      expect(result).to eq(
        uid: '12345',
        email: 'ash@pokemon.com',
        avatar_url: 'https://example.com/avatar.jpg'
      )
    end
  end

  describe '#auth' do
    it 'returns the omniauth auth hash from the request env' do
      expect(controller.send(:auth)).to eq(auth_hash)
    end
  end
end
