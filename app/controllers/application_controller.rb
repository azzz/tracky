class ApplicationController < ActionController::API
  include Knock::Authenticable
  include ResponsesHandler

  protected

  def current_ability
    Ability.new(current_user)
  end

  # def authenticate_user
  #   binding.pry
  # end
end
