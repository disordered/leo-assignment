# Provides CRUD operations for "/images/" path.
class ImagesController < ApplicationController
  # POST /images
  def create
    file = params[:image]
    if file.nil?
      render json: { error: "'Image' form data missing"}, status: :bad_request
    else
      image = Image.create(filename: file.original_filename,
                           mime_type: file.content_type,
                           size: file.size,
                           data: file.read)

      head :ok, location: image
    end
  end

  # GET /images/:id
  def show
    id = params[:id]
    image = Image.find_by_id(id)
    if image.nil?
      render json: { error: "Image with id '#{id}' not found"}, status: :not_found
    else
      send_data image.data, filename: image.filename, content_type: image.mime_type
    end
  end
end