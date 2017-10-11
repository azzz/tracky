module ResponsesHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordInvalid, with: :render_422
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    rescue_from CanCan::AccessDenied, with: :render_401
  end

  def render_401(exception)
    render_error(exception, code: 401)
  end

  def render_422(exception)
    render_error(exception, payload: {errors: exception.record.errors.messages}, code: 422)
  end

  def render_404(exception)
    render_error(exception, code: 404)
  end

  def render_error(exception, payload: {}, code:)
    payload = payload.dup
    payload[:message] = exception.message
    payload[:backtrace] = exception.backtrace if !Rails.env.production? && params[:_debug]

    render json: payload, status: code
  end
end
