class UsersController < ApplicationController
  def create
    user = User.create!(user_params)
    session[:user_id] = user.id
    cookies.signed[:user_id] = user.id
    render json: user, status: :created
  end

  def show
    user = User.find(session[:user_id])
    if user
      render json: user, status: :ok
    else
      render json: { error: "Unauthorized user" }, status: :unauthorized
    end
  end

  private

  def user_params
    params.permit(:username, :password)
  end
end
