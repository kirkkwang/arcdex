# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Bulbapedia::Client do
  subject(:client) { described_class.new }

  let(:http) { instance_double(HTTP::Client) }
  let(:status) { instance_double(HTTP::Response::Status, success?: true) }

  before { allow(HTTP).to receive(:headers).and_return(http) }

  # Stub the HTTP boundary: each body becomes one parsed JSON response.
  def stub_api(*bodies)
    responses = bodies.map { |body| instance_double(HTTP::Response, status: status, parse: body) }
    allow(http).to receive(:get).and_return(*responses)
  end

  def revision(title, wikitext)
    { 'title' => title, 'revisions' => [{ 'slots' => { 'main' => { '*' => wikitext } } }] }
  end

  describe '#pages_wikitext' do
    it 'resolves normalization then redirects to the right page wikitext' do
      stub_api(
        'query' => {
          'normalized' => [{ 'from' => 'iron bundle ex (Paradox Drive 81)', 'to' => 'Iron Bundle ex (Paradox Drive 81)' }],
          'redirects' => [{ 'from' => 'Iron Bundle ex (Paradox Drive 81)', 'to' => 'Iron Bundle ex (Paradox Drive 13)' }],
          'pages' => { '1' => revision('Iron Bundle ex (Paradox Drive 13)', 'WIKITEXT') }
        }
      )
      result = client.pages_wikitext(['iron bundle ex (Paradox Drive 81)'])
      expect(result['iron bundle ex (Paradox Drive 81)']).to eq('WIKITEXT')
    end

    it 'maps a missing/unknown title to nil' do
      stub_api('query' => { 'pages' => {} })
      expect(client.pages_wikitext(['Nope'])).to eq('Nope' => nil)
    end

    it 'batches requests in groups of at most 50' do
      stub_api('query' => { 'pages' => {} })
      client.pages_wikitext((1..120).map { |n| "Card #{n}" })
      expect(http).to have_received(:get).exactly(3).times # 50 + 50 + 20
    end
  end

  describe '#category_members' do
    it 'follows continuation across pages' do
      stub_api(
        { 'query' => { 'categorymembers' => [{ 'title' => 'A' }] }, 'continue' => { 'cmcontinue' => 'x' } },
        { 'query' => { 'categorymembers' => [{ 'title' => 'B' }] } }
      )
      expect(client.category_members('Category:Foo')).to eq(%w[A B])
    end
  end

  describe '#image_url' do
    it 'extracts the direct image URL' do
      stub_api('query' => { 'pages' => { '1' => { 'imageinfo' => [{ 'url' => 'https://x/y.png' }] } } })
      expect(client.image_url('Foo.png')).to eq('https://x/y.png')
    end

    it 'returns nil for a missing file' do
      stub_api('query' => { 'pages' => { '-1' => { 'missing' => '' } } })
      expect(client.image_url('Nope.png')).to be_nil
    end
  end

  describe 'API error handling' do
    it 'raises on a non-maxlag API error instead of returning an empty body' do
      stub_api('error' => { 'code' => 'badvalue', 'info' => 'bad' })
      expect { client.image_url('Foo.png') }.to raise_error(/badvalue/)
    end
  end
end
