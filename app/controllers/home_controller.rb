class HomeController < ApplicationController
  before_action :authenticate_user, only: %i[secret]

  def show
    if current_user
      render json: {message: "Welcome back, #{current_user.full_name}"}
    else
      render json: {message: 'There are no fish'}
    end
  end

  def secret
    render json: {message: 'You found a cow level!'}
  end
end
