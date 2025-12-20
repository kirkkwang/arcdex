RSpec.describe 'Catalog search' do
  it 'displays the search interface' do
    visit root_path

    expect(page).to have_current_path('/catalog?q=&search_field=all_fields&view=gallery')
    expect(page).to have_css('#search_field')
    expect(page).to have_button('search')
  end
end
