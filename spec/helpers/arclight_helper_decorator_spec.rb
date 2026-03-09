# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArclightHelperDecorator do
  describe '#show_content_classes' do
    it 'returns the custom content column classes' do
      expect(helper.show_content_classes).to eq('col-12 col-lg-9 show-document order-2')
    end
  end

  describe '#show_sidebar_classes' do
    it 'returns the custom sidebar column classes' do
      expect(helper.show_sidebar_classes).to eq('col-lg-3 order-1 collection-sidebar')
    end
  end

  describe '#repository_path' do
    # Test via direct extend to avoid the Rails route helper of the same name
    # overriding the decorator method in the helper spec's view context
    let(:obj) { Object.new.tap { |o| o.extend(described_class) } }

    it 'returns a /repositories/ path using the given name' do
      expect(obj.repository_path('Base Set')).to eq('/repositories/Base Set')
    end
  end

  describe '#sanitized_nest_path' do
    context 'when nest_path contains /components#' do
      before { allow(helper).to receive(:params).and_return({ nest_path: '/components#anchor' }) }

      it 'returns the nest_path' do
        expect(helper.sanitized_nest_path).to eq('/components#anchor')
      end
    end

    context 'when nest_path does not contain /components#' do
      before { allow(helper).to receive(:params).and_return({ nest_path: '/other/path' }) }

      it 'returns nil' do
        expect(helper.sanitized_nest_path).to be_nil
      end
    end

    context 'when nest_path is nil' do
      before { allow(helper).to receive(:params).and_return({ nest_path: nil }) }

      it 'returns nil' do
        expect(helper.sanitized_nest_path).to be_nil
      end
    end
  end

  describe '#repository_collections_path' do
    # search_action_url is a Blacklight controller helper, not on ActionView::Base
    # so we test via a plain object extended with the module + a defined singleton method
    let(:repository) { double('repository', name: 'Base Set') } # rubocop:disable RSpec/VerifiedDoubles
    let(:obj) do
      Object.new.tap do |o|
        o.extend(described_class)
        o.define_singleton_method(:search_action_url) { |params| "/catalog?#{params}" }
      end
    end

    it 'builds a search URL filtered to the repository series and Sets category' do
      allow(obj).to receive(:search_action_url).and_call_original
      obj.repository_collections_path(repository)
      expect(obj).to have_received(:search_action_url).with(hash_including(f: { series: ['Base Set'], Category: ['Set'] }))
    end
  end

  describe '#bookmarks_to_catalog_search_path' do
    let(:bookmarks) { double('bookmarks') } # rubocop:disable RSpec/VerifiedDoubles
    let(:obj) do
      Object.new.tap do |o|
        o.extend(described_class)
        o.define_singleton_method(:search_catalog_url) { |params| "/catalog/search?#{params}" }
      end
    end

    before { allow(bookmarks).to receive(:pluck).with(:document_id).and_return(%w[base-1-001 base-1-002]) }

    it 'calls search_catalog_url with joined document ids' do
      allow(obj).to receive(:search_catalog_url).and_call_original
      obj.bookmarks_to_catalog_search_path(bookmarks)
      expect(obj).to have_received(:search_catalog_url).with(
        hash_including(
          search_field: 'id',
          q: 'base-1-001 OR base-1-002',
          view: 'gallery'
        )
      )
    end
  end

  describe '#mirador_viewer' do
    let(:obj) do
      Object.new.tap do |o|
        o.extend(described_class)
        o.define_singleton_method(:manifest_repository_url) { |id| "https://example.com/repo/#{id}/manifest" }
        o.define_singleton_method(:manifest_solr_document_url) { |id| "https://example.com/catalog/#{id}/manifest" }
        o.define_singleton_method(:cookies) { {} }
      end
    end

    # Arclight::Repository.find is backed by RequestStore cache. Seed it directly
    # to avoid querying Solr and to control what find returns.
    after { RequestStore.store.delete(:arclight_repositories) }

    context 'when the id belongs to a Repository' do
      before { RequestStore.store[:arclight_repositories] = [double('repo', name: 'Base Set')] } # rubocop:disable RSpec/VerifiedDoubles

      it 'builds a mirador URL using manifest_repository_url' do
        result = obj.mirador_viewer(id: 'Base Set')
        expect(result).to include('manifest=')
        expect(result).to include('repo')
      end
    end

    context 'when the id does not belong to a Repository' do
      before { RequestStore.store[:arclight_repositories] = [] }

      it 'builds a mirador URL using manifest_solr_document_url' do
        result = obj.mirador_viewer(id: 'base-1-001')
        expect(result).to include('manifest=')
        expect(result).to include('catalog')
      end
    end

    context 'when encode: true' do
      before { RequestStore.store[:arclight_repositories] = [] }

      it 'encodes the id with Arcdex::Hashids' do
        allow(Arcdex::Hashids).to receive(:encode).with(42).and_return('abc12345')
        result = obj.mirador_viewer(id: 42, encode: true)
        expect(result).to include('abc12345')
      end
    end
  end

  describe '#preferred_theme' do
    context 'when the theme cookie is set' do
      before { allow(helper).to receive(:cookies).and_return({ theme: 'light' }) }

      it 'returns the cookie value' do
        expect(helper.preferred_theme).to eq('light')
      end
    end

    context 'when no theme cookie is present' do
      before { allow(helper).to receive(:cookies).and_return({}) }

      it 'defaults to dark' do
        expect(helper.preferred_theme).to eq('dark')
      end
    end
  end
end
