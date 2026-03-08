# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  def build_user(attrs = {})
    described_class.new({ email: 'test@example.com', password: 'password123' }.merge(attrs))
  end

  describe '#ordered_bookmark_ids' do
    it 'returns bookmark_order when it is set' do
      user = build_user(bookmark_order: %w[doc-3 doc-1 doc-2])
      expect(user.ordered_bookmark_ids).to eq(%w[doc-3 doc-1 doc-2])
    end

    it 'falls back to bookmarks ordered by created_at when bookmark_order is empty' do
      user = build_user(bookmark_order: [])
      bookmark = instance_double(Bookmark, document_id: 'doc-1')
      allow(user).to receive(:bookmarks).and_return(
        double('relation', order: double('ordered', pluck: ['doc-1'])) # rubocop:disable RSpec/VerifiedDoubles
      )
      expect(user.ordered_bookmark_ids).to eq(['doc-1'])
    end
  end

  describe '#update_bookmark_order!' do
    it 'persists the new bookmark order' do
      user = build_user
      allow(user).to receive(:update!)
      user.update_bookmark_order!(%w[doc-2 doc-1])
      expect(user).to have_received(:update!).with(bookmark_order: %w[doc-2 doc-1])
    end
  end

  describe '.from_google' do
    let(:google_data) do
      { uid: '12345', email: 'ash@pokemon.com', avatar_url: 'https://example.com/avatar.jpg' }
    end

    it 'creates a new user from Google data' do
      expect do
        described_class.from_google(google_data)
      end.to change(described_class, :count).by(1)
    end

    it 'returns the existing user on a second call with the same email' do
      described_class.from_google(google_data)
      expect do
        described_class.from_google(google_data)
      end.not_to change(described_class, :count)
    end

    it 'sets uid, provider, and avatar_url on creation' do
      user = described_class.from_google(google_data)
      expect(user.uid).to eq('12345')
      expect(user.provider).to eq('google')
      expect(user.avatar_url).to eq('https://example.com/avatar.jpg')
    end
  end
end
