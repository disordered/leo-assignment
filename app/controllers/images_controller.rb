require 'pagy'
require 'pagy/extras/headers'

# Provides CRUD operations for "/images/" path.
class ImagesController < ApplicationController
  include Pagy::Backend

  DEFAULT_PAGE_SIZE = 5

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

  # DELETE /images/:id
  def destroy
    id = params[:id]
    image = Image.find_by_id(id)
    if image.nil?
      render json: { error: "Image with id '#{id}' not found"}, status: :not_found
    else
      image.destroy
    end
  end

  # GET /images
  def index
    # Overriding default page size in the interest of time
    # This will disable client specified page size
    pagy, records = pagy(Image.all, items: DEFAULT_PAGE_SIZE)

    # Add RFC-8288 pagination support
    pagy_headers_merge(pagy)
    render json: records.pluck(:id, :filename, :size, :mime_type).map { |id, filename, size, mime_type|
      {
          location: image_url(id),
          id: id,
          filename: filename,
          size: size,
          mime_type: mime_type
      }
    }
  end
end