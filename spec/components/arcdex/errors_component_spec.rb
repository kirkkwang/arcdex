# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::ErrorsComponent, type: :component do
  describe '404' do
    subject(:component) { described_class.new(404) }

    it 'renders the error container' do
      render_inline(component)
      expect(page).to have_css('.error-container')
    end

    it 'shows the 404 status code in the heading' do
      render_inline(component)
      expect(page).to have_css('h1', text: /404/)
    end

    it 'shows the not-found header text' do
      render_inline(component)
      expect(page).to have_text("Oh no, this page doesn't exist.")
    end

    it 'shows the hint to check the URL' do
      render_inline(component)
      expect(page).to have_text('Check the URL and try again!')
    end
  end

  describe '500' do
    subject(:component) { described_class.new(500) }

    it 'shows the 500 status code in the heading' do
      render_inline(component)
      expect(page).to have_css('h1', text: /500/)
    end

    it 'shows the uh-oh header text' do
      render_inline(component)
      expect(page).to have_text('Uh oh, something went wrong.')
    end

    it 'shows the contact message' do
      render_inline(component)
      expect(page).to have_text('If you have my contact, let me know!')
    end
  end
end
