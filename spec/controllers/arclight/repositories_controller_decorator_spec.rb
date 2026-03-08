# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arclight::RepositoriesController do
  let(:old_repo) do
    instance_double(Arclight::Repository,
                    name: 'Jungle',
                    final_set_release_date: Date.new(2020, 1, 1),
                    documents: [])
  end

  let(:new_repo) do
    instance_double(Arclight::Repository,
                    name: 'Base Set',
                    final_set_release_date: Date.new(2023, 6, 1),
                    documents: [])
  end

  before { allow(Arclight::Repository).to receive(:all).and_return([old_repo, new_repo]) }

  describe '#index' do
    before { get :index }

    it 'assigns repositories sorted by release date descending' do
      expect(assigns(:repositories)).to eq([new_repo, old_repo])
    end
  end

  describe '#show' do
    let(:first_doc) { instance_double(SolrDocument) }
    let(:second_doc) { instance_double(SolrDocument) }

    # Override old_repo at this scope to add documents
    let(:old_repo) do
      instance_double(Arclight::Repository,
                      name: 'Jungle',
                      final_set_release_date: Date.new(2020, 1, 1),
                      documents: [first_doc, second_doc])
    end

    # find delegates to all.find { name == id }, so all stub covers it
    before { get :show, params: { id: 'Jungle' } }

    it 'assigns the repository' do
      expect(assigns(:repository)).to eq(old_repo)
    end

    it 'assigns documents in reverse order' do
      expect(assigns(:collections)).to eq([second_doc, first_doc])
    end
  end
end
