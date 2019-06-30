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
    assert_equal SMALL_JPG, image.filename
    assert_equal fixture.size, image.size
    assert_equal SMALL_JPG_MIME, image.mime_type
    assert FileUtils.compare_stream(File.new(fixture), StringIO.new(image.data))
  end

  test 'post without file data should result in bad request' do
    assert_no_difference 'Image.count' do
      post images_url
      assert_response :bad_request
    end

    assert JSON.parse(response.body).key?('error'), 'Error message should be included in response'
  end
end
