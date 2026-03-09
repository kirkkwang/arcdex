# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arclight::RepositoryDecorator do
  let(:earlier_doc) do
    double('earlier_doc', series: 'Base', release_date: Date.new(1999, 1, 9)) # rubocop:disable RSpec/VerifiedDoubles
  end
  let(:later_doc) do
    double('later_doc', series: 'Base', release_date: Date.new(1999, 6, 16)) # rubocop:disable RSpec/VerifiedDoubles
  end
  let(:search_result) { double('search_result', documents: [later_doc, earlier_doc]) } # rubocop:disable RSpec/VerifiedDoubles
  let(:search_service) { double('search_service', search: search_result) } # rubocop:disable RSpec/VerifiedDoubles
  let(:repo_class) { double('repo_class', new: search_service) } # rubocop:disable RSpec/VerifiedDoubles

  before do
    RequestStore.store.clear
    allow(Blacklight).to receive(:repository_class).and_return(repo_class)
    allow(repo_class).to receive(:new).and_return(search_service)
  end

  after { RequestStore.store.clear }

  describe '.all' do
    it 'returns an array of Repository objects grouped by series' do
      repos = Arclight::Repository.all
      expect(repos).to all(be_a(Arclight::Repository))
      expect(repos.map(&:name)).to include('Base')
    end

    it 'caches the result in RequestStore' do
      Arclight::Repository.all
      Arclight::Repository.all
      expect(search_service).to have_received(:search).once
    end
  end

  describe '.find' do
    it 'returns the repository matching the given name' do
      repo = Arclight::Repository.find('Base')
      expect(repo.name).to eq('Base')
    end

    it 'returns nil when no repository matches' do
      expect(Arclight::Repository.find('Unknown Series')).to be_nil
    end
  end

  describe '#initialize' do
    it 'sorts documents by release_date ascending' do
      repo = Arclight::Repository.new('Base', [later_doc, earlier_doc])
      expect(repo.documents).to eq([earlier_doc, later_doc])
    end
  end

  describe '#final_set_release_date' do
    it 'returns the release_date of the last document' do
      repo = Arclight::Repository.new('Base', [earlier_doc, later_doc])
      expect(repo.final_set_release_date).to eq(Date.new(1999, 6, 16))
    end
  end

  describe '#slug' do
    it 'returns the repository name' do
      repo = Arclight::Repository.new('Base', [earlier_doc])
      expect(repo.slug).to eq('Base')
    end
  end

  describe '#attributes' do
    it 'returns an empty array' do
      repo = Arclight::Repository.new('Base', [earlier_doc])
      expect(repo.attributes).to eq([])
    end
  end

  describe '#request_types' do
    it 'returns an empty array' do
      repo = Arclight::Repository.new('Base', [earlier_doc])
      expect(repo.request_types).to eq([])
    end
  end
end
