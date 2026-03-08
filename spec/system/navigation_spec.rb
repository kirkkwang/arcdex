# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Navigation' do
  before { visit root_path }

  describe 'navbar links' do
    it 'shows a Series link' do
      expect(page).to have_link(I18n.t('arclight.routes.series'), href: /\/series/)
    end

    it 'shows a Sets link that filters by Set category' do
      expect(page).to have_link(I18n.t('arclight.routes.sets'), href: /Category.*Set|f.*Category/)
    end

    it 'shows a Cards link that filters by Card category' do
      expect(page).to have_link(I18n.t('arclight.routes.cards'), href: /Category.*Card|f.*Category/)
    end
  end

  describe 'authentication links' do
    it 'shows the login button when unauthenticated' do
      expect(page).to have_button(I18n.t('blacklight.header_links.login'))
    end

    it 'the login button posts to the Google OAuth path' do
      form = find("form[action*='google_oauth2']", visible: false)
      expect(form['method'].downcase).to eq('post')
    end
  end

  describe 'search form' do
    it 'has a search input field' do
      expect(page).to have_css('#search_field')
    end

    it 'has a search submit button' do
      expect(page).to have_button('search')
    end

    it 'submitting the form updates the URL with the query' do
      fill_in 'q', with: 'charizard'
      click_on 'search'
      expect(page).to have_current_path(/q=charizard/)
    end
  end
end
