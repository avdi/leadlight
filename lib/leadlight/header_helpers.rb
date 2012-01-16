module Leadlight
  module HeaderHelpers
    def clean_content_type(content_type)
      unless content_type.nil?
        mimetype = MIME::Type.new(content_type)
        content_type = "#{mimetype.media_type}/#{mimetype.sub_type}"
      end
      content_type
    end
  end
end
