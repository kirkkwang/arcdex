class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::LocalePicker::Concern
  layout :determine_layout if respond_to? :layout

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :render_nav_bar_locale

  def render_nav_bar_locale
    # Don't render the spot for the locales if we don't have any
    # otherwise an unwanted divider would render
    blacklight_config.navbar.partials.delete(:locale) unless helpers.available_locales.many?
  end
end
