# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Theme controller' do
  before { visit root_path }

  def click_theme_button(theme)
    page.execute_script(
      "document.querySelector('[data-action=\"theme#set#{theme.capitalize}\"]').click()"
    )
  end

  def html_theme
    find('html')['data-bs-theme']
  end

  def local_storage_theme
    page.evaluate_script("localStorage.getItem('theme')")
  end

  def aria_pressed_for(theme)
    find("[data-bs-theme-value='#{theme}']", visible: false)['aria-pressed']
  end

  describe 'on connect' do
    it 'marks the current theme button as pressed' do
      current_theme = html_theme
      expect(aria_pressed_for(current_theme)).to eq('true')
    end

    it 'marks the other theme button as not pressed' do
      other_theme = html_theme == 'dark' ? 'light' : 'dark'
      expect(aria_pressed_for(other_theme)).to eq('false')
    end
  end

  describe 'setting light theme' do
    before { click_theme_button('light') }

    it 'sets data-bs-theme to light on the html element' do
      expect(html_theme).to eq('light')
    end

    it 'persists the choice to localStorage' do
      expect(local_storage_theme).to eq('light')
    end

    it 'marks the light button as pressed' do
      expect(aria_pressed_for('light')).to eq('true')
    end

    it 'marks the dark button as not pressed' do
      expect(aria_pressed_for('dark')).to eq('false')
    end
  end

  describe 'setting dark theme' do
    before { click_theme_button('dark') }

    it 'sets data-bs-theme to dark on the html element' do
      expect(html_theme).to eq('dark')
    end

    it 'persists the choice to localStorage' do
      expect(local_storage_theme).to eq('dark')
    end

    it 'marks the dark button as pressed' do
      expect(aria_pressed_for('dark')).to eq('true')
    end

    it 'marks the light button as not pressed' do
      expect(aria_pressed_for('light')).to eq('false')
    end
  end
end
