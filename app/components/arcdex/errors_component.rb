module Arcdex
  class ErrorsComponent < ViewComponent::Base
    attr_reader :status_code

    def initialize(status_code)
      @status_code = status_code
    end

    private

    def header
      case status_code
      when 500
        'Uh oh, something went wrong.'
      else
        "Oh no, this page doesn't exist."
      end
    end

    def paragraph
      case status_code
      when 500
        'If you have my contact, let me know!'
      else
        'Check the URL and try again!'
      end
    end
  end
end
