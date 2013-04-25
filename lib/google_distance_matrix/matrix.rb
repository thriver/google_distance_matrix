module GoogleDistanceMatrix
  # Public: Represents a distance matrix.
  #
  # Enables you to set up a origins and destinations and get
  # a distance matrix from Google. For documentation see
  # https://developers.google.com/maps/documentation/distancematrix
  #
  # Examples
  #
  #   origin_1 = GoogleDistanceMatrix::Place.new address: "Karl Johans gate, Oslo"
  #   origin_2 = GoogleDistanceMatrix::Place.new address: "Askerveien 1, Asker"
  #
  #   destination_1 = GoogleDistanceMatrix::Place.new address: "Drammensveien 1, Oslo"
  #   destination_2 = GoogleDistanceMatrix::Place.new lat: 1.4, lng: 1.3
  #
  #   matrix = GoogleDistanceMatrix::Matrix.new(
  #     origins: [origin_1, origin_2],
  #     destinations: [destination_1, destination_2]
  #   )
  #
  # If you want to may configure the matrix. See GoogleDistanceMatrix::Configuration.
  #
  #   matrix.configure do |config|
  #     config.sensor = true
  #     config.mode = "walking"
  #   end
  #
  # Query API and get the matrix back
  #
  #   matrix.matrix # Returns a two dimensional array.
  #                 # Rows are ordered according to the values in the origins.
  #                 # Each row corresponds to an origin, and each element within that row corresponds to
  #                 # a pairing of the origin with a destination.
  #
  #
  class Matrix
    include ActiveModel::Validations

    validates :origins, length: {minimum: 1, too_short: "must have at least one origin"}
    validates :destinations, length: {minimum: 1, too_short: "must have at least one destination"}
    validate { errors.add(:configuration, "is invalid") if configuration.invalid? }

    attr_reader :origins, :destinations, :configuration

    def initialize(attributes = {})
      attributes = attributes.with_indifferent_access

      @origins = Places.new attributes[:origins]
      @destinations = Places.new attributes[:destinations]
      @configuration = attributes[:configuration] || GoogleDistanceMatrix.default_configuration.dup
    end


    def matrix
      @matrix ||= load_matrix
    end



    def configure
      yield configuration
    end

    def url
      UrlBuilder.new(self).url
    end



    private

    def load_matrix
      parsed = JSON.parse client.get(url).body

      parsed["rows"].each_with_index.map do |row, origin_index|
        origin = origins[origin_index]

        row["elements"].each_with_index.map do |element, destination_index|
          route_attributes = element.merge(origin: origin, destination: destinations[destination_index])
          Route.new route_attributes
        end
      end
    end

    def client
      @client ||= Client.new
    end
end
end
