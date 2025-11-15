module Arcdex
  module Icons
    class AdvancedSearchComponent < ::Blacklight::Icons::IconComponent
      self.svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" aria-hidden="true" width="24" height="24" viewBox="0 0 24 24">
          <path fill="none" d="M0 0h24v24H0V0z"/>
          <path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/>
          <path fill="none" stroke="currentColor" stroke-width="2" d="M20,1 L20,7 M17,4 L23,4"/>
        </svg>
      SVG

      def self.plus = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" aria-hidden="true" width="18" height="18" viewBox="0 0 24 24">
          <path d="M19 13H13V19H11V13H5V11H11V5H13V11H19V13Z" transform="scale(1.3) translate(-2.5, -2.5)"/>
        </svg>
      SVG

      def self.minus = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" aria-hidden="true" width="18" height="18" viewBox="0 0 24 24">
          <path d="M19 13H5V11H19V13Z" transform="scale(1.3) translate(-2.5, -2.5)"/>
        </svg>
      SVG
    end
  end
end
