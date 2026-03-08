# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::UpperMetadataLayoutComponent do
  subject(:component) { described_class.new(field:) }

  let(:document) { SolrDocument.new('id' => 'base-4', 'title_ssm' => ['Charizard']) }
  let(:field_config) { double('field_config', compact: false, truncate: false) } # rubocop:disable RSpec/VerifiedDoubles
  let(:field) { double('field', document:, field_config:, key: 'upper_metadata') } # rubocop:disable RSpec/VerifiedDoubles


  describe '#initialize' do
    it 'exposes the field via the reader' do
      expect(component.field).to eq(field)
    end

    it 'sets document from field.document' do
      expect(component.document).to eq(document)
    end
  end
end
