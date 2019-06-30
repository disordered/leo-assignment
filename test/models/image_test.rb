require 'mimemagic'
require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  SMALL_JPG = 'small.jpg'
  SMALL_JPG_MIME = 'image/jpeg'

  test 'jpg can be stored' do
    file_path = file_fixture(SMALL_JPG)
    assert_difference 'Image.count' do
      image = Image.create(filename: SMALL_JPG,
                           size: file_path.size,
                           mime_type: MimeMagic.by_path(file_path),
                           data: file_path.read)

      actual_image = Image.find(image.id)
      assert_equal SMALL_JPG, actual_image.filename
      assert_equal file_path.size, actual_image.size
      assert_equal SMALL_JPG_MIME, actual_image.mime_type
      assert_equal file_path.read, actual_image.data
    end
  end

  test 'image data is required' do
    file_path = file_fixture(SMALL_JPG)

    image = Image.new
    image.filename = SMALL_JPG
    image.size = file_path.size
    image.mime_type = MimeMagic.by_path(file_path)
    image.data = nil

    assert_raises(ActiveRecord::NotNullViolation) { image.save }
  end

  test 'non-data fields are optional' do
    Image.create(data: file_fixture(SMALL_JPG).read)
  end
end
