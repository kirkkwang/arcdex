# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Infinite scroll controller' do
  def inject_infinite_scroll_html(current_page: 1, total_pages: 3)
    page.execute_script(<<~JS)
      const html = `
        <div id="infinite-scroll-fixture"
             data-controller="infinite-scroll"
             data-infinite-scroll-url-value="/catalog"
             data-infinite-scroll-current-page-value="#{current_page}"
             data-infinite-scroll-total-pages-value="#{total_pages}">
          <div id="documents">
            <div class="document">Doc 1</div>
          </div>
          <nav data-infinite-scroll-target="pagination">Page nav</nav>
        </div>`;
      document.body.insertAdjacentHTML('beforeend', html);
    JS
    sleep 0.1 # wait for Stimulus to connect
  end

  def get_controller
    page.execute_script(<<~JS)
      const el = document.getElementById('infinite-scroll-fixture');
      window._infiniteScrollController = window.Stimulus.getControllerForElementAndIdentifier(el, 'infinite-scroll');
    JS
  end

  before do
    visit root_path
    inject_infinite_scroll_html
    get_controller
  end

  describe 'connect' do
    it 'hides the pagination element' do
      display = page.evaluate_script(
        "document.querySelector('#infinite-scroll-fixture [data-infinite-scroll-target=\"pagination\"]').style.display"
      )
      expect(display).to eq('none')
    end

    it 'creates a loading indicator in the DOM' do
      expect(page.evaluate_script(
               "!!document.querySelector('#infinite-scroll-fixture [data-infinite-scroll-target=\"loadingIndicator\"]')"
             )).to be true
    end

    it 'initialises the loading indicator as hidden' do
      display = page.evaluate_script(
        "document.querySelector('#infinite-scroll-fixture [data-infinite-scroll-target=\"loadingIndicator\"]').style.display"
      )
      expect(display).to eq('none')
    end
  end

  describe 'showLoadingIndicator / hideLoadingIndicator' do
    it 'makes the loading indicator visible' do
      page.execute_script('window._infiniteScrollController.showLoadingIndicator()')
      display = page.evaluate_script(
        "document.querySelector('#infinite-scroll-fixture [data-infinite-scroll-target=\"loadingIndicator\"]').style.display"
      )
      expect(display).to eq('block')
    end

    it 'hides the loading indicator again' do
      page.execute_script('window._infiniteScrollController.showLoadingIndicator()')
      page.execute_script('window._infiniteScrollController.hideLoadingIndicator()')
      display = page.evaluate_script(
        "document.querySelector('#infinite-scroll-fixture [data-infinite-scroll-target=\"loadingIndicator\"]').style.display"
      )
      expect(display).to eq('none')
    end
  end

  describe 'handleScroll' do
    it 'does not trigger a load when already at the last page' do
      page.execute_script(<<~JS)
        window._infiniteScrollController.currentPageValue = 3;
        window._infiniteScrollController.totalPagesValue  = 3;
        window._infiniteScrollController.handleScroll();
      JS
      expect(page.evaluate_script('window._infiniteScrollController.loadingValue')).to be false
    end

    it 'does not trigger a load when already loading' do
      page.execute_script(<<~JS)
        window._infiniteScrollController.loadingValue = true;
        window._infiniteScrollController.handleScroll();
      JS
      expect(page.evaluate_script('window._infiniteScrollController.loadingValue')).to be true
    end
  end

  describe 'appendDocuments' do
    it 'appends new document HTML into the #documents container' do
      page.execute_script(<<~JS)
        window._infiniteScrollController.appendDocuments(
          '<div id="documents"><div class="document">Doc 2</div></div>',
          1
        );
      JS
      expect(page.evaluate_script("document.querySelectorAll('#infinite-scroll-fixture .document').length")).to eq(2)
    end
  end
end
