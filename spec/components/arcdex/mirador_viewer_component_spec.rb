# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::MiradorViewerComponent, type: :component do
  let(:component) { described_class.new(id: 'base-1-001') }

  before do
    allow(component).to receive(:helpers).and_return(
      double('helpers', mirador_viewer: '/mirador_viewer.html?manifest=test') # rubocop:disable RSpec/VerifiedDoubles
    )
  end

  describe '#viewer (private)' do
    it 'renders an iframe with the mirador viewer URL' do
      result = render_inline(component)
      expect(result.css('iframe').first['src']).to include('mirador_viewer')
    end
  end
end
