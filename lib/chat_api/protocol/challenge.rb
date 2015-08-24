# encoding: utf-8
module Dora
  module Protocol
    class Challenge
      attr_reader :data, :id

      def initialize(id)
        @id = id
        challenge_filename = File.join(Dora.data, DATA_FOLDER + "/nextChallenge.#{id}.dat")
        if File.exist?(challenge_filename) && File.readable?(challenge_filename)
          challenge_data = open(challenge_filename).read
          if challenge_data
            @data = challenge_data.force_encoding(BINARY_ENCODING)
          end
        end
      end

      def data=(v)
        @data = v
      end

      def write_data=(v)
        IO.write(File.join(Dora.data, DATA_FOLDER+"/nextChallenge.#{@id}.dat"), v)
      end
    end
  end
end
