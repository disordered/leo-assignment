# Provides CRUD operations for "/images/" path.
class ImagesController < ApplicationController
  # POST /images
  def create
    file = params[:image]
    if file.nil?
      render json: { error: '"Image" form data missing'}, status: :bad_request
    else
      image = Image.create(filename: file.original_filename,
                           mime_type: file.content_type,
                           size: file.size,
                           data: file.read)

      head :ok, location: image
    end
  end
end