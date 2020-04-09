require 'mime/types'

module LinkedIn
  # Rich Media APIs
  #
  # @see https://developer.linkedin.com/docs/guide/v2/shares/rich-media-shares
  #
  # [(contribute here)](https://github.com/mdesjardins/linkedin-v2)
  class Media < APIResource
    def summary(options = {})
      path = "/richMediaSummariesV2/#{options.delete(:id)}"
      get(path, options)
    end

    # Uploads rich media content to LinkedIn from a supplied URL.
    #
    # @see https://developer.linkedin.com/docs/guide/v2/shares/rich-media-shares#upload
    #
    # @options options [String] :source_url, the URL to the content to be uploaded.
    # @options options [Numeric] :timeout, optional timeout value in seconds, defaults to 300.
    # @options options [String] :disposition_filename, the name of the file to be uploaded. Defaults to the basename of the URL filename.
    # @return [LinkedIn::Mash]
    #
    def upload(options = {})
      source_url = options.delete(:source_url)
      test_url = "https://scontent-ort2-2.xx.fbcdn.net/v/t1.0-9/92571139_841576939695766_5109866619484504064_n.jpg?_nc_cat=103&_nc_sid=2d5d41&_nc_ohc=kzffbOhmQdEAX959JbO&_nc_ht=scontent-ort2-2.xx&oh=e98afa20bf9833f32cf069417610cf26&oe=5EB55454"
      registration_endpoint = '/assets?action=registerUpload'

      registration_body = {
        "registerUploadRequest": {
          "owner": options[:owner],
          "recipes": [
            "urn:li:digitalmediaRecipe:feedshare-image"
          ],
          "serviceRelationships": [
            {
              "identifier": "urn:li:userGeneratedContent",
              "relationshipType": "OWNER"
            }
          ]
        }
      }

      registration_response = post(registration_endpoint,  MultiJson.dump(registration_body), "Content-Type" => "application/json")
      mash_registration_response = Mash.from_json(registration_response.body)['value']
      upload_url = mash_registration_response['uploadMechanism']['com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest']['uploadUrl']
      asset = mash_registration_response['asset']
      fileData = file(test_url, options)

      response =
        @connection.put(upload_url, fileData) do |req|
          req.headers['Content-Length'] = req.body.length.to_s
          req.headers['Content-Type'] = fileData.content_type
        end

      asset
    end

    private

    def upload_filename(media)
      File.basename(media.base_uri.request_uri)
    end

    def file(source_url, options)
      media = open(source_url, 'rb')
      io = StringIO.new(media.read)
      filename = options.delete(:disposition_filename) || upload_filename(media)
      Faraday::UploadIO.new(io, media.content_type, filename)
    end
  end
end
