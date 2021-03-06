require 'mimemagic'
require 'json'
require 'test_helper'
require 'uri'

class ImagesControllerTest < ActionDispatch::IntegrationTest
  SMALL_JPG = 'small.jpg'
  SMALL_JPG_FIXTURE = "files/#{SMALL_JPG}"
  SMALL_JPG_MIME = 'image/jpeg'

  test 'file can be uploaded' do
    fixture = fixture_file_upload(SMALL_JPG_FIXTURE, SMALL_JPG_MIME)

    assert_difference 'Image.count' do
      post images_url, params: { image: fixture }
      assert_response :ok
    end

    location = response.header['Location']
    assert_not location.blank?, 'Location header should be returned'

    # Take last element of the path, which will be the id value of the image
    image = Image.find(URI::parse(location).path.split('/').last)
    assert_fixture_equals_image SMALL_JPG, image
  end

  test 'post without file data should result in bad request' do
    assert_no_difference 'Image.count' do
      post images_url
      assert_response :bad_request
      assert_response_contains_error
    end
  end

  test 'get returns existing image' do
    image = create_image(SMALL_JPG)
    get image_url(image)
    assert_response :ok

    assert_fixture_equals_image SMALL_JPG, image
  end

  test 'get with invalid id results in not found' do
    invalid_id = -1
    assert_not Image.exists?(invalid_id), "Precondition failure, record with id '#{invalid_id}' exists"

    get image_url(invalid_id)
    assert_response :not_found
    assert_response_contains_error
  end

  test 'delete removes specified record' do
    image1 = create_image(SMALL_JPG)
    image2 = create_image(SMALL_JPG)
    deleted_image = create_image(SMALL_JPG)

    assert_difference 'Image.count', -1 do
      delete image_url(deleted_image)
    end

    assert_response :no_content
    assert_equal 2, Image.where(id: [image1, image2]).count, 'Incorrect image deleted'
  end

  test 'list returns a list of image meta data' do
    expected_json = []
    3.times do
      image = create_image(SMALL_JPG)
      expected_json << {
          location: image_url(image.id),
          id: image.id,
          filename: image.filename,
          size: image.size,
          mime_type: image.mime_type
      }
    end

    get images_url
    assert_response :ok

    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal expected_json, json
  end

  test 'list returns empty when there are no images' do
    get images_url
    assert_response :ok

    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal 0, json.size, 'Should have returned empty json'
  end

  test 'list limits response to page size' do
    (ImagesController::DEFAULT_PAGE_SIZE + 1).times do
      create_image(SMALL_JPG)
    end

    get images_url
    assert_response :ok

    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal ImagesController::DEFAULT_PAGE_SIZE, json.size, 'Items in result does not match page size'

    headers = response.headers
    assert_equal 1, headers['Current-Page'], 'Should be on first page'
    assert_equal ImagesController::DEFAULT_PAGE_SIZE, headers['Page-Items'], 'Page size should match'
    assert_equal 2, headers['Total-Pages'], 'Should have two pages'
    assert_equal ImagesController::DEFAULT_PAGE_SIZE + 1, headers['Total-Count'], 'Total record count does not match'
  end

  test 'list can paginate' do
    (ImagesController::DEFAULT_PAGE_SIZE + 1).times do
      create_image(SMALL_JPG)
    end

    get images_url, params: { page: 2 }
    assert_response :ok

    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal 1, json.size, 'There should be only one item on second page'

    headers = response.headers
    assert_equal 2, headers['Current-Page'], 'Should be on second page'
    assert_equal ImagesController::DEFAULT_PAGE_SIZE, headers['Page-Items'], 'Page size should match'
    assert_equal 2, headers['Total-Pages'], 'Should have two pages'
    assert_equal ImagesController::DEFAULT_PAGE_SIZE + 1, headers['Total-Count'], 'Total record count does not match'
  end

  private

  # Compares data, size, filename and mime type of provided fixture name against provided image record
  # @param filename [String] filename from 'fixtures/files'
  # @param image [Image] Image application record
  def assert_fixture_equals_image(filename, image)
    fixture = file_fixture(filename)
    assert_equal filename, image.filename
    assert_equal fixture.size, image.size
    assert_equal MimeMagic.by_path(fixture), image.mime_type
    assert FileUtils.compare_stream(File.new(fixture), StringIO.new(image.data))
  end

  # Inserts new Image record based on provided fixture file.
  # @param filename [String] filename from 'fixture/files'
  # @return [Image] inserted Image record
  def create_image(filename)
    fixture = file_fixture(filename)
    Image.create(filename: filename,
                 size: fixture.size,
                 mime_type: MimeMagic.by_path(fixture),
                 data: fixture.read)
  end

  # Checks that returned response contains an error message
  def assert_response_contains_error
    assert JSON.parse(response.body).key?('error'), 'Error message should be included in response'
  end
end
