# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Autocomplete controller' do
  before { visit root_path }

  describe 'blur' do
    it 'hides the popup when the input loses focus' do
      # Reveal the popup, then blur the input to trigger the hide
      page.execute_script("document.getElementById('autocomplete-popup').hidden = false")
      find('[data-autocomplete-target="input"]').trigger('blur')
      expect(page.evaluate_script("document.getElementById('autocomplete-popup').hidden")).to be true
    end
  end

  describe 'preventHide' do
    it 'keeps the popup visible when clicking inside it' do
      page.execute_script("document.getElementById('autocomplete-popup').hidden = false")
      # mousedown on the popup should call preventDefault, keeping it visible
      find_by_id('autocomplete-popup', visible: false).trigger('mousedown')
      expect(page.evaluate_script("document.getElementById('autocomplete-popup').hidden")).to be false
    end
  end
end
