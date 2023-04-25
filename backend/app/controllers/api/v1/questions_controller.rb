require 'csv'
require 'ruby/openai'
require 'json'
require 'dotenv'
require 'resemble'
require 'nmatrix'
require 'numo/narray'

# use ada cause newer and cheaper, can replace DOC and QUERY and SEARCH
DOC_EMBEDDINGS_MODEL_ADA = "text-embedding-ada-002"

module Api
  module V1
    class QuestionsController < ApplicationController
      def ask
        question = params[:question]

        # Check if question ends in ?
        unless question.end_with?('?')
          question += '?'
        end

        # Check cache if question already exists

        # Read pages.csv file
        df = CSV.read('pdf-sample.pdf.pages.csv', headers: true)

        # Load embeddings embeddings.csv file
        document_embeddings = load_embeddings('pdf-sample.pdf.embeddings.csv')

        # Answer question with context and get answer and context for saving


        # Cache answer, context, question

        # Return answer

        # Temporary for testing
        answer = question

        render json: { answer: question }
      end

      private

      def load_embeddings(fname)
        df = CSV.read(fname, headers: true)
        max_dim = df.headers.map(&:to_i).max
        df.each_with_object({}) do |row, h|
          h[row['title']] = (0..max_dim).map { |i| row[i.to_s].to_f }
        end
      end

      def get_embedding(text, model)
        client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
        result = client.embeddings(
          engine: DOC_EMBEDDINGS_MODEL_ADA,
          prompt: text
        )
        result['choices'][0]['text'].strip
      end

      def search_book_embeddings(question)
        # Implementation
      end

      def cache_answer(question, answer)
        # Implementation
      end

      def send_to_openai_embedding_api(question, answer)
        # Implementation
      end
    end
  end
end
