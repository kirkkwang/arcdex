# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show page controller' do
  describe 'connect' do
    context 'when there is no URL anchor' do
      it 'does not trigger a page reload' do
        visit root_path
        initial_url = current_url

        # Inject the show-page controller onto the page
        page.execute_script(<<~JS)
          const div = document.createElement('div');
          div.setAttribute('data-controller', 'show-page');
          document.body.appendChild(div);
        JS

        sleep 0.4 # wait longer than the 200ms setTimeout
        expect(current_url).to eq(initial_url)
      end
    end

    context 'when a URL anchor is present' do
      it 'schedules a location.href reset after 200ms to follow the anchor' do
        visit root_path

        page.execute_script("history.replaceState(null, '', window.location.href + '#test-anchor')")

        # Intercept setTimeout so we can inspect what the controller schedules
        page.execute_script(<<~JS)
          window._capturedDelay = null;
          const orig = window.setTimeout;
          window.setTimeout = function(fn, delay) { window._capturedDelay = delay; return orig(fn, delay); };
        JS

        page.execute_script(<<~JS)
          const div = document.createElement('div');
          div.setAttribute('data-controller', 'show-page');
          document.body.appendChild(div);
        JS

        sleep 0.1 # wait for Stimulus to connect the controller
        expect(page.evaluate_script('window._capturedDelay')).to eq(200)
      end
    end
  end
end
