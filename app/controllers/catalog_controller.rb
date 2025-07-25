# frozen_string_literal: true

# Blacklight controller that handles searches and document requests
class CatalogController < ApplicationController
  include Blacklight::Catalog
  include BlacklightRangeLimit::ControllerOverride
  include Arclight::Catalog

  before_action :modify_sort, only: [:index]

  class_attribute :tcg_price_desc_field, default: 'tcg_player_market_price_isi desc'
  class_attribute :tcg_price_asc_field, default: 'tcg_player_market_price_isi asc'
  class_attribute :cardmarket_desc_field, default: 'cardmarket_avg7_price_isi desc'
  class_attribute :cardmarket_asc_field, default: 'cardmarket_avg7_price_isi asc'

  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    config.advanced_search[:enabled] = true
    config.advanced_search[:form_solr_paramters] = {}
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'edismax'
    config.view.gallery(document_component: Blacklight::Gallery::DocumentComponent, icon: Blacklight::Gallery::Icons::GalleryComponent)
    # config.view.masonry(document_component: Blacklight::Gallery::DocumentComponent, icon: Blacklight::Gallery::Icons::MasonryComponent)
    # config.view.slideshow(document_component: Blacklight::Gallery::SlideshowComponent, icon: Blacklight::Gallery::Icons::SlideshowComponent)
    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials ||= []
    config.show.partials.insert(1, :openseadragon)
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10,
      fl: '*,collection:[subquery]',
      'collection.q': '{!terms f=id v=$row._root_}',
      'collection.defType': 'lucene',
      'collection.fl': '*',
      'collection.rows': 1
    }

    # Sets the indexed Solr field that will display with highlighted matches
    config.highlight_field = 'text'

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [30]

    # turn on bookmarks with a configuration
    config.bookmarks = true

    ## Default parameters to send on single-document requests to Solr.
    ## These settings are the Blacklight defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
      qt: 'document',
      fl: '*,collection:[subquery],cards:[subquery]',

      'collection.q': '{!terms f=id v=$row._root_}',
      'collection.defType': 'lucene',
      'collection.fl': '*',
      'collection.rows': 1,

      'cards.q': '{!terms f=_root_ v=$row._root_}',
      'cards.fq': '-level_ssm:"collection"',
      'cards.defType': 'lucene',
      'cards.fl': 'id,title_ssm',
      'cards.sort': 'sort_ssi asc',
      'cards.rows': 10_000
    }

    config.header_component = Arclight::HeaderComponent
    # config.add_results_document_tool(:online, component: Arclight::OnlineStatusIndicatorComponent)
    config.add_results_document_tool(:arclight_bookmark_control, component: Arclight::BookmarkComponent) if config.bookmarks == true

    config.add_results_collection_tool(:group_toggle, unless: ->(controller, _field, _facet_field) do
      controller.params[:f]&.keys&.include?('set')
    end)
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?) if config.bookmarks == true
    # config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')
    config.add_nav_action(:theme_picker, partial: 'arcdex/nav/theme_picker', additional_classes: 'dropdown')

    # solr field configuration for search results/index views
    config.index.partials = %i[arclight_index_default]
    config.index.title_field = 'normalized_title_ssm'
    config.index.display_type_field = 'level_ssm'
    config.index.title_component = Arcdex::Blacklight::DocumentTitleComponent
    config.index.document_component = Arclight::SearchResultComponent
    config.index.group_component = Arcdex::Arclight::GroupComponent
    config.index.constraints_component = Arclight::ConstraintsComponent
    config.index.constraints_component_exclude_styling = 'text-decoration-line-through'
    config.index.document_presenter_class = Arclight::IndexPresenter
    config.index.search_bar_component = Arcdex::Arclight::SearchBarComponent
    config.index.thumbnail_field = 'thumbnail_path_ssi'
    config.index.thumbnail_component = Arcdex::Blacklight::Document::ThumbnailComponent

    # solr field configuration for document/show views
    # config.show.title_field = 'title_display'
    config.show.document_component = Arcdex::Arclight::DocumentComponent
    config.show.sidebar_component = Arcdex::Arclight::SidebarComponent
    config.show.breadcrumb_component = Arclight::BreadcrumbsHierarchyComponent
    config.show.embed_component = Arclight::EmbedComponent
    config.show.access_component = Arcdex::PricesMetadataComponent
    config.show.online_status_component = Arclight::OnlineStatusIndicatorComponent
    config.show.expand_hierarchy_component = Arclight::ExpandHierarchyButtonComponent
    config.show.display_type_field = 'level_ssm'
    config.show.thumbnail_field = 'thumbnail_path_ssi'
    config.show.document_presenter_class = Arclight::ShowPresenter
    config.show.metadata_partials = %i[
      summary_field
      indexed_terms_field
    ]

    config.show.component_metadata_partials = %i[
      component_field
      component_indexed_terms_field
    ]

    config.show.component_access_items = %i[
      component_terms_field
    ]

    ##
    # Compact index view
    # config.view.compact!

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically
    #  across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation
    #  (note: It is case sensitive when searching values)

    config.add_facet_field 'Category', field: 'level_ssim', limit: 10, excludable: true
    config.add_facet_field 'series', field: 'series_ssm', limit: 10, excludable: true
    config.add_facet_field 'set', field: 'collection_ssim', limit: 10, excludable: true
    config.add_facet_field 'rarity', field: 'rarity_ssm', limit: 10, excludable: true
    config.add_facet_field 'tcg_player_market_price', label: 'TCGplayer Market Price', field: 'tcg_player_market_price_isi', range: true, range_config: {
      show_missing_link: false
    }, if: ->(_controller, _field, facet_field) do
      facet_field.response.facet_counts['facet_fields']['tcg_player_market_price_isi'].present?
    end
    config.add_facet_field 'cardmarket_avg7_price', label: 'Cardmarket Avg7 Price', field: 'cardmarket_avg7_price_isi', range: true, range_config: {
      show_missing_link: false
    }, if: ->(_controller, _field, facet_field) do
      facet_field.response.facet_counts['facet_fields']['cardmarket_avg7_price_isi'].present?
    end
    config.add_facet_field 'national pokex no.', field: 'national_pokedex_numbers_isim', range: true, range_config: {
      show_missing_link: false
    }, if: ->(_controller, _field, facet_field) do
      facet_field.response.facet_counts['facet_fields']['national_pokedex_numbers_isim'].present?
    end
    config.add_facet_field 'release year', field: 'release_year_isi', range: true, range_config: {
      show_missing_link: false
    }
    config.add_facet_field 'supertype', field: 'supertype_ssm', limit: 10, excludable: true
    config.add_facet_field 'subtypes', field: 'subtypes_ssm', limit: 10, excludable: true
    config.add_facet_field 'Hit Points', field: 'hp_isi', range: true, range_config: {
      show_missing_link: false
    }, if: ->(_controller, _field, facet_field) do
      facet_field.response.facet_counts['facet_fields']['hp_isi'].present?
    end
    config.add_facet_field 'types', field: 'types_ssm', excludable: true
    config.add_facet_field 'number of abilities', field: 'number_of_abilities_isi', range: true, range_config: {
      show_missing_link: false
    }, if: ->(_controller, _field, facet_field) do
      facet_field.response.facet_counts['facet_fields']['number_of_abilities_isi'].present?
    end
    config.add_facet_field 'number of attacks', field: 'number_of_attacks_isi', range: true, range_config: {
      show_missing_link: false
    }, if: ->(_controller, _field, facet_field) do
      facet_field.response.facet_counts['facet_fields']['number_of_attacks_isi'].present?
    end
    config.add_facet_field 'weakness type', field: 'weakness_type_ssm', excludable: true
    config.add_facet_field 'retreat cost', field: 'converted_retreat_cost_isi', range: true, range_config: {
      show_missing_link: false
    }, if: ->(_controller, _field, facet_field) do
      facet_field.response.facet_counts['facet_fields']['converted_retreat_cost_isi'].present?
    end
    config.add_facet_field 'artist', field: 'artist_ssm', limit: 10, excludable: true


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'highlight', accessor: 'highlights', separator_options: {
      words_connector: '<br/>',
      two_words_connector: '<br/>',
      last_word_connector: '<br/>'
    }, compact: true, component: Arclight::IndexMetadataFieldComponent
    # config.add_index_field "creator", accessor: true, component: Arclight::IndexMetadataFieldComponent
    # config.add_index_field "abstract_or_scope", accessor: true, truncate: true, repository_context: true, helper_method: :render_html_tags, component: Arclight::IndexMetadataFieldComponent
    config.add_index_field 'flavor_text_html', accessor: 'flavor_text_html', component: Arclight::IndexMetadataFieldComponent, helper_method: :render_html_tags, if: ->(controller, _field, _document) { controller.params[:view] == 'list' }
    config.add_index_field 'breadcrumbs', accessor: :itself, component: Arclight::SearchResultBreadcrumbsComponent, compact: { count: 2 }, if: ->(controller, _field, _document) { controller.params[:view] == 'list' }

    config.add_facet_field 'access', query: {
      online: { label: 'Online access', fq: 'has_online_content_ssim:true' }
    }

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field 'all_fields', label: 'All Fields' do |field|
      field.include_in_simple_select = true
    end

    config.add_search_field 'card_name', label: 'Card Name' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: 'title_tesim',
        pf: 'title_tesim',
        fq: ['level_ssim:Card']
      }
    end

    config.add_search_field 'set_name', label: 'Set Name' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: 'title_tesim',
        pf: 'title_tesim',
        fq: ['level_ssim:Set']
      }
    end

    config.add_search_field 'artist', label: 'Artist' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: 'artist_tesim',
        pf: 'artist_tesim'
      }
    end

    config.add_search_field 'id', label: 'ID' do |field|
      field.qt = 'search'
      field.solr_parameters = {
        qf: 'id',
        pf: 'id'
      }
    end

    # Field-based searches. We have registered handlers in the Solr configuration
    # so we have Blacklight use the `qt` parameter to invoke them
    # config.add_search_field "keyword", label: "Keyword" do |field|
    #   field.qt = "search" # default
    # end

    # These are the parameters passed through in search_state.params_for_search
    config.search_state_fields += %i[id group hierarchy_context original_document]
    config.search_state_fields << { original_parents: [] }

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field tcg_price_desc_field, label: 'TCGplayer market price ($$$ to $)'
    config.add_sort_field tcg_price_asc_field, label: 'TCGplayer market price ($ to $)'
    config.add_sort_field cardmarket_desc_field, label: 'Cardmarket avg7 price ($$$ to $)'
    config.add_sort_field cardmarket_asc_field, label: 'Cardmarket avg7 price ($ to $)'
    config.add_sort_field 'release_date_sort desc, sort_ssi asc', label: 'release date (new to old)'
    config.add_sort_field 'release_date_sort asc, sort_ssi asc', label: 'release date (old to new)'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'


    # ===========================
    # COLLECTION SHOW PAGE FIELDS
    # ===========================

    # Collection Show Page - Summary Section
    config.add_summary_field 'logo', field: 'logo_url_html_ssm', helper_method: :render_html_tags, component: Arcdex::CardViewComponent

    # Collection Show Page - Indexed Terms Section
    config.add_indexed_terms_field 'series', field: 'series_ssim', link_to_facet: true
    config.add_indexed_terms_field 'set', field: 'normalized_title_ssm', link_to_facet: true
    config.add_indexed_terms_field 'complete set count', field: 'printed_total_ssim'
    config.add_indexed_terms_field 'master set count', field: 'total_items_ssim', if: ->(_controller, _field, document) { document.master_set? }
    config.add_indexed_terms_field 'release date', field: 'release_date_ssm'
    config.add_indexed_terms_field label: 'TCG Code', field: 'ptcgo_code_ssim'
    config.add_indexed_terms_field 'symbol', field: 'symbol_url_html_ssm', helper_method: :render_html_tags

    # ==========================
    # COMPONENT SHOW PAGE FIELDS
    # ==========================

    # Component Show Page - Metadata Section
    # config.add_component_field "containers", accessor: "containers", separator_options: {
    #   words_connector: ", ",
    #   two_words_connector: ", ",
    #   last_word_connector: ", "
    # }, if: lambda { |_context, _field_config, document|
    #   document.containers.present?
    # }

    config.add_component_field 'Card', field: 'large_url_html_ssm', helper_method: :render_html_tags, component: Arcdex::CardViewComponent

    config.add_component_indexed_terms_field 'name', field: 'normalized_title_ssm', component: Arcdex::PokemonSearchComponent
    config.add_component_indexed_terms_field 'set', field: 'parent_unittitles_ssm', link_to_facet: true
    config.add_component_indexed_terms_field 'supertype', field: 'supertype_ssm', link_to_facet: true
    config.add_component_indexed_terms_field 'national_pokedex_number', field: 'national_pokedex_numbers_isim'
    config.add_component_indexed_terms_field 'subtypes', field: 'subtypes_ssm', link_to_facet: true
    config.add_component_indexed_terms_field 'level', field: 'level_ssi'
    config.add_component_indexed_terms_field 'types', label: 'Type(s)', field: 'types_ssm', link_to_facet: true
    config.add_component_indexed_terms_field 'rarity', field: 'rarity_ssm', link_to_facet: true
    config.add_component_indexed_terms_field 'evolves_from', field: 'evolves_from_ssm', component: Arcdex::PokemonSearchComponent
    config.add_component_indexed_terms_field 'evolves_to', field: 'evolves_to_ssm', component: Arcdex::PokemonSearchComponent
    config.add_component_indexed_terms_field 'card number', field: 'number_ssm'
    config.add_component_indexed_terms_field 'artist', field: 'artist_ssm', link_to_facet: true

    # # Component Show Page - Indexed Terms Section
    # config.add_component_indexed_terms_field "access_subjects", field: "access_subjects_ssim", link_to_facet: true, separator_options: {
    #   words_connector: "<br/>",
    #   two_words_connector: "<br/>",
    #   last_word_connector: "<br/>"
    # }

    # config.add_component_indexed_terms_field "names", field: "names_ssim", separator_options: {
    #   words_connector: "<br/>",
    #   two_words_connector: "<br/>",
    #   last_word_connector: "<br/>"
    # }, helper_method: :link_to_name_facet

    # config.add_component_indexed_terms_field "places", field: "places_ssim", link_to_facet: true, separator_options: {
    #   words_connector: "<br/>",
    #   two_words_connector: "<br/>",
    #   last_word_connector: "<br/>"
    # }

    # config.add_component_indexed_terms_field "indexes", field: "indexes_html_tesm",
    #                                           helper_method: :render_html_tags

    # =================
    # ACCESS TAB FIELDS
    # =================

    # Collection Show Page Access Tab - Terms and Conditions Section
    config.add_terms_field 'restrictions', field: 'accessrestrict_html_tesm', helper_method: :render_html_tags
    config.add_terms_field 'terms', field: 'userestrict_html_tesm', helper_method: :render_html_tags

    # Component Show Page Access Tab - Terms and Condition Section
    config.add_component_terms_field 'tcg_player_prices', label: 'TCGplayer Prices', field: 'tcg_player_prices_json_ssi', component: Arcdex::TcgPlayerPricesComponent
    config.add_component_terms_field 'cardmarket_prices', label: 'Cardmarket Prices', field: 'cardmarket_prices_json_ssi', component: Arcdex::CardmarketPricesComponent
    # Collection and Component Show Page Access Tab - In Person Section
    config.add_in_person_field 'repository_location', values: ->(_, document, _) { document.repository_config }, component: Arclight::RepositoryLocationComponent
    config.add_in_person_field 'before_you_visit', values: ->(_, document, _) { document.repository_config&.visit_note }

    # Collection and Component Show Page Access Tab - How to Cite Section
    config.add_cite_field 'prefercite', field: 'prefercite_html_tesm', helper_method: :render_html_tags

    # Collection and Component Show Page Access Tab - Contact Section
    config.add_contact_field 'repository_contact', values: ->(_, document, _) { document.repository_config&.contact }

    # Group header values
    config.add_group_header_field 'abstract_or_scope', accessor: true, truncate: true, helper_method: :render_html_tags
  end

  def index
    @response = search_service.search_results

    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render layout: false }
      format.atom { render layout: false }
      format.json do
        if params[:infinite_scroll]
          # For infinite scroll, render the documents using the HTML partial
          render json: {
            documents_html: render_to_string(
              partial: 'document_list',
              formats: [:html],  # Force HTML format
              locals: {
                documents: @response.documents,
                view_config: blacklight_config.view_config(params[:view] || 'gallery')
              }
            ),
            pagination: {
              current_page: @response.current_page,
              total_pages: @response.total_pages,
              next_page: @response.next_page,
              has_next_page: @response.next_page.present?
            }
          }
        else
          # Standard JSON response
          @presenter = Blacklight::JsonPresenter.new(@response, blacklight_config)
        end
      end
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  private

  def modify_sort
    if params[:range]&.fetch('tcg_player_market_price', nil).nil?
      blacklight_config.sort_fields.delete(tcg_price_desc_field)
      blacklight_config.sort_fields.delete(tcg_price_asc_field)
    end
    if params[:range]&.fetch('cardmarket_avg7_price', nil).nil?
      blacklight_config.sort_fields.delete(cardmarket_desc_field)
      blacklight_config.sort_fields.delete(cardmarket_asc_field)
    end
  end
end
