class UsersController < ApplicationController
  authorize_resource
  load_and_authorize_resource only: :show

  def create
    user = User.new user_data
    user.password_confirmation = user.password
    user.save!

    token = Knock::AuthToken.new(payload: {sub: user.id}).token
    render json: {jwt: token}, status: :created
  end

  def show
    render json: {user: @user}, except: :password_digest
  end

  private

  def user_data
    params.require(:user).permit(:email, :full_name, :password)
  end
end
