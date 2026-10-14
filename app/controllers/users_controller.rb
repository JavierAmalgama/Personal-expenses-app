class UsersController < ApplicationController
    def create
        user = User.create!(user_params)
        render_object user
    end

    def show
        render_object User.find(params[:id])
    end
    
    def index
        render_collection User.all
    end
    
    private
    
    def user_params
        params.permit(:name,:email)
    end
end
