class UsersController < ApplicationController
  def create
    user = User.new user_data
    user.password_confirmation = user.password
    user.save!

    token = Knock::AuthToken.new(payload: {sub: user.id}).token
    render json: {jwt: token}, status: :created
  end

  private

  def user_data
    params.require(:user).permit(:email, :full_name, :password)
  end
end
