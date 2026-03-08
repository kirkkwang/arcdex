# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sortable controller' do
  def inject_sortable_html
    page.execute_script(<<~JS)
      const html = `
        <div id="sortable-fixture" data-controller="sortable">
          <div data-document-id="3"><img class="img-thumbnail" src="" alt=""></div>
          <div data-document-id="1"><img class="img-thumbnail" src="" alt=""></div>
          <div data-document-id="2"><img class="img-thumbnail" src="" alt=""></div>
        </div>`;
      document.body.insertAdjacentHTML('beforeend', html);
    JS
    sleep 0.2 # wait for Stimulus to connect and ActionCable to initialise
  end

  def get_controller
    page.execute_script(<<~JS)
      const el = document.getElementById('sortable-fixture');
      window._sortableController = window.Stimulus.getControllerForElementAndIdentifier(el, 'sortable');
    JS
  end

  def document_order
    page.evaluate_script(
      "Array.from(document.querySelectorAll('#sortable-fixture [data-document-id]')).map(el => el.dataset.documentId)"
    )
  end

  before do
    visit root_path
    inject_sortable_html
    get_controller
  end

  describe 'connect' do
    it 'initialises a Sortable instance on the element' do
      expect(page.evaluate_script('!!window._sortableController.sortable')).to be true
    end
  end

  describe 'reorderElements' do
    it 'rearranges child elements to match the given order' do
      page.execute_script("window._sortableController.reorderElements(['1', '2', '3'])")
      expect(document_order).to eq(%w[1 2 3])
    end

    it 'ignores ids not present in the container' do
      page.execute_script("window._sortableController.reorderElements(['1', '99', '2', '3'])")
      expect(document_order).to eq(%w[1 2 3])
    end
  end

  describe 'handleRemoteOrderUpdate' do
    it 'reorders the elements according to the new order' do
      page.execute_script("window._sortableController.handleRemoteOrderUpdate(['2', '3', '1'])")
      expect(document_order).to eq(%w[2 3 1])
    end

    it 'sets isUpdating to true during the update then resets it' do
      page.execute_script("window._sortableController.handleRemoteOrderUpdate(['1', '2', '3'])")
      sleep 0.2 # wait for the 100ms setTimeout to reset the flag
      expect(page.evaluate_script('window._sortableController.isUpdating')).to be false
    end
  end
end
