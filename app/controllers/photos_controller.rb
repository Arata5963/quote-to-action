# app/controllers/photos_controller.rb
class PhotosController < ApplicationController
  before_action :set_photo, only: [ :show, :edit, :update ]

  def index
    @photos = Photo.all
  end

  def new
    @photo = Photo.new
  end

  def create
    @photo = Photo.new(photo_params)

    if @photo.save
      redirect_to @photo, notice: "写真がアップロードされました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @photo.update(photo_params)
      redirect_to @photo, notice: "写真が更新されました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_photo
    @photo = Photo.find(params[:id])
  end

  def photo_params
    params.require(:photo).permit(:title, :image)
  end
end
