class ErrorsController < ApplicationController
  layout 'layouts/blacklight/base'

  def show
    @exception = request.env['action_dispatch.exception']
    @status_code = @exception.try(:status_code) ||
                    ActionDispatch::ExceptionWrapper.new(
                      request.env, @exception
                   ).status_code
    @header = header[@status_code.to_s]
    @paragraph = paragraph[@status_code.to_s]

    render :show, status: @status_code
  end

  private

  def header
    {
      '404' => "Oh no, this page doesn't exist.",
      '500' => 'Uh oh, something went wrong.'
    }
  end

  def paragraph
    {
      '404' => 'Check the URL and try again!',
      '500' => 'If you have my contact, let me know!'
    }
  end
end
