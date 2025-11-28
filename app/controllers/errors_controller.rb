class ErrorsController < ApplicationController
  layout 'layouts/blacklight/base'

  def show
    exception = request.env['action_dispatch.exception']
    status_code = ActionDispatch::ExceptionWrapper.new(request.env, exception).status_code

    render Arcdex::ErrorsComponent.new(status_code), status: status_code
  end
end
