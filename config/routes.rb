Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new

  ##### REMOVE SEARCH HISTORY #####
  # Note: has to be before we mount Blacklight::Engine
  get '/search_history', to: 'application#render404'
  delete '/search_history/clear', to: 'application#render404'

  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'
  mount Arclight::Engine => '/'

  # OVERRIDE Arclight repository routes to use /series instead
  # this is for anything that still uses /repositories or /repository/:id
  get '/series', to: 'arclight/repositories#index', as: 'repositories'
  get '/series/:id', to: 'arclight/repositories#show', as: 'repository'

  get '/series', to: 'arclight/repositories#index', as: 'series'
  get '/series/:id', to: 'arclight/repositories#show', as: 'serie'

  root to: redirect { '/catalog?q=&search_field=all_fields&view=gallery' }
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable
  end

  devise_for :user, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  concern :exportable, Blacklight::Routes::Exportable.new
  concern :hierarchy, Arclight::Routes::Hierarchy.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :hierarchy
    concerns :exportable

    member do
      get 'manifest', to: 'catalog#iiif_manifest', defaults: { format: 'json' }, constraints: { format: 'json' }
    end
  end

  ##### TOGGLEABLE BOOKMARK via CatalogtController #####
  if CatalogController.blacklight_config.bookmarks == true
    resources :bookmarks, only: [:index, :update, :create, :destroy] do
      concerns :exportable

      collection do
        delete 'clear'
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
