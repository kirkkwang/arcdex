# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Image zoom controller' do
  # Inject the full controller HTML structure since it lives on document show
  # pages that require Solr data. We test the JS behaviour in isolation.
  def inject_zoom_html(image_count: 2, fixture_id: 'zoom-fixture')
    images = (1..image_count).map do |i|
      "<img data-image-zoom-target='trigger'
            data-zoomed-image-url='https://example.com/zoom#{i}.jpg'
            data-action='click->image-zoom#open'
            src='https://example.com/thumb#{i}.jpg'
            alt='Image #{i}'>"
    end.join

    page.execute_script(<<~JS)
      const html = `
        <div id="#{fixture_id}" data-controller="image-zoom">
          #{images}
          <div data-image-zoom-target="overlay"
               class="zoom-overlay"
               data-action="click->image-zoom#close">
            <img data-image-zoom-target="zoomImage"
                 src=""
                 alt="Zoomed image"
                 data-action="click->image-zoom#preventClose">
            <button data-action="image-zoom#nextImage">Next</button>
            <button data-action="image-zoom#previousImage">Prev</button>
          </div>
        </div>`;
      document.body.insertAdjacentHTML('beforeend', html);
    JS
    sleep 0.1 # wait for Stimulus to connect
  end

  def get_controller(fixture_id: 'zoom-fixture')
    page.execute_script(<<~JS)
      const el = document.getElementById('#{fixture_id}');
      window._zoomController = window.Stimulus.getControllerForElementAndIdentifier(el, 'image-zoom');
    JS
  end

  def open_zoom(trigger_index: 0, fixture_id: 'zoom-fixture')
    page.execute_script(<<~JS)
      const el = document.getElementById('#{fixture_id}');
      const trigger = el.querySelectorAll('[data-image-zoom-target="trigger"]')[#{trigger_index}];
      window._zoomController.open({ currentTarget: trigger });
    JS
  end

  def dispatch_key(key)
    page.execute_script("document.dispatchEvent(new KeyboardEvent('keydown', { key: '#{key}', bubbles: true }))")
  end

  before do
    visit root_path
    inject_zoom_html
    get_controller
  end

  describe 'open' do
    before { open_zoom }

    it 'adds the active class to the overlay' do
      expect(page.evaluate_script("document.querySelector('#zoom-fixture [data-image-zoom-target=\"overlay\"]').classList.contains('active')")).to be true
    end

    it 'adds zoom-active to the body' do
      expect(page.evaluate_script("document.body.classList.contains('zoom-active')")).to be true
    end

    it 'sets isZoomOpen to true' do
      expect(page.evaluate_script("window._zoomController.isZoomOpen")).to be true
    end

    it 'sets the zoomed image src to the first image' do
      src = page.evaluate_script("document.querySelector('#zoom-fixture [data-image-zoom-target=\"zoomImage\"]').src")
      expect(src).to include('zoom1.jpg')
    end
  end

  describe 'close' do
    before do
      open_zoom
      page.execute_script("window._zoomController.close()")
    end

    it 'removes the active class from the overlay' do
      expect(page.evaluate_script("document.querySelector('#zoom-fixture [data-image-zoom-target=\"overlay\"]').classList.contains('active')")).to be false
    end

    it 'removes zoom-active from the body' do
      expect(page.evaluate_script("document.body.classList.contains('zoom-active')")).to be false
    end

    it 'sets isZoomOpen to false' do
      expect(page.evaluate_script("window._zoomController.isZoomOpen")).to be false
    end
  end

  describe 'keyboard navigation' do
    before { open_zoom }

    it 'pressing Escape closes the zoom' do
      dispatch_key('Escape')
      expect(page.evaluate_script("window._zoomController.isZoomOpen")).to be false
    end

    it 'pressing ArrowRight advances to the next image' do
      dispatch_key('ArrowRight')
      src = page.evaluate_script("document.querySelector('#zoom-fixture [data-image-zoom-target=\"zoomImage\"]').src")
      expect(src).to include('zoom2.jpg')
    end

    it 'pressing ArrowLeft wraps around to the last image from index 0' do
      dispatch_key('ArrowLeft')
      src = page.evaluate_script("document.querySelector('#zoom-fixture [data-image-zoom-target=\"zoomImage\"]').src")
      expect(src).to include('zoom2.jpg')
    end
  end

  describe 'nextImage / previousImage' do
    before { open_zoom }

    it 'nextImage advances the index and updates the zoomed image' do
      page.execute_script("window._zoomController.nextImage()")
      src = page.evaluate_script("document.querySelector('#zoom-fixture [data-image-zoom-target=\"zoomImage\"]').src")
      expect(src).to include('zoom2.jpg')
    end

    it 'previousImage wraps around to the last image from index 0' do
      page.execute_script("window._zoomController.previousImage()")
      src = page.evaluate_script("document.querySelector('#zoom-fixture [data-image-zoom-target=\"zoomImage\"]').src")
      expect(src).to include('zoom2.jpg')
    end
  end

  describe 'single image' do
    before do
      # Remove the 2-image fixture so imageElements count is unambiguous
      page.execute_script("document.getElementById('zoom-fixture').remove()")
      inject_zoom_html(image_count: 1, fixture_id: 'zoom-fixture-single')
      get_controller(fixture_id: 'zoom-fixture-single')
      open_zoom(fixture_id: 'zoom-fixture-single')
    end

    it 'sets data-single-image to true on the overlay' do
      overlay = page.evaluate_script("document.querySelector('#zoom-fixture-single [data-image-zoom-target=\"overlay\"]').dataset.singleImage")
      expect(overlay).to eq('true')
    end
  end
end
