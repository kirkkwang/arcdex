# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Scroll position controller' do
  before { visit root_path }

  # Capybara/Playwright returns {} for sessionStorage string values when using
  # evaluate_script directly, so we use boolean JS expressions instead.
  def session_key_present?
    page.evaluate_script("sessionStorage.getItem('arclight-scroll-position') !== null")
  end

  def session_key_absent?
    page.evaluate_script("sessionStorage.getItem('arclight-scroll-position') === null")
  end

  def click_link_without_navigating(selector)
    page.execute_script(<<~JS)
      document.addEventListener('click', e => e.preventDefault(), { capture: true, once: true });
      document.querySelector(#{selector.to_json}).click();
    JS
  end

  describe 'storeScrollPosition' do
    before { page.execute_script("sessionStorage.removeItem('arclight-scroll-position')") }

    it 'saves the scroll position to sessionStorage when a cross-page link is clicked' do
      # Inject the controller (the results container may not render on empty searches)
      page.execute_script(<<~JS)
        const div = document.createElement('div');
        div.setAttribute('data-controller', 'scroll-position');
        document.body.appendChild(div);
      JS
      sleep 0.1 # wait for Stimulus to connect

      # Call storeScrollPosition directly via the Stimulus controller instance
      page.execute_script(<<~JS)
        const el = document.querySelector('[data-controller="scroll-position"]');
        const controller = window.Stimulus.getControllerForElementAndIdentifier(el, 'scroll-position');
        const fakeLink = document.createElement('a');
        fakeLink.href = '/catalog?q=other';
        controller.storeScrollPosition({ currentTarget: fakeLink });
      JS
      sleep 0.1
      expect(session_key_present?).to be true
    end

    it 'does not store position for same-page anchor links' do
      # Inject and click a same-page anchor link
      page.execute_script(<<~JS)
        document.addEventListener('click', e => e.preventDefault(), { capture: true, once: true });
        const a = document.createElement('a');
        a.href = window.location.href.split('#')[0] + '#some-anchor';
        document.body.appendChild(a);
        a.click();
      JS
      sleep 0.1
      expect(session_key_absent?).to be true
    end
  end

  describe 'restoreScrollPosition' do
    it 'removes the stored position from sessionStorage after using it' do
      page.execute_script("sessionStorage.setItem('arclight-scroll-position', '500')")

      page.execute_script(<<~JS)
        const div = document.createElement('div');
        div.setAttribute('data-controller', 'scroll-position');
        document.body.appendChild(div);
      JS

      sleep 0.2 # wait for requestAnimationFrame to fire
      expect(session_key_absent?).to be true
    end
  end
end
