require 'csv'
require 'openai'
require 'json'
require 'dotenv'
require 'resemble'

Dotenv.load('.env')

# use ada cause newer and cheaper, can replace DOC and QUERY and SEARCH
DOC_EMBEDDINGS_MODEL_ADA = "text-embedding-ada-002"
COMPLETIONS_MODEL = 'text-davinci-003'

MAX_SECTION_LEN = 500
SEPARATOR = "\n* "
separator_len = 3

COMPLETIONS_API_PARAMS = {
  'temperature' => 0.0,
  'max_tokens' => 150,
  'model' => COMPLETIONS_MODEL
}

module Api
  module V1
    class QuestionsController < ApplicationController
      def ask
        user_question = params[:question]

        unless user_question.end_with?('?')
          user_question += '?'
        end

        # Check cache if question already exists
        answer = Rails.cache.read(user_question)

        if answer.nil?
          # Check database to see if question already exists there
          question = Question.find_by(question: user_question)

          if question
            answer = question.answer
            # Add the answer to the cache for next hour
            cache_answer(user_question, answer)
          else
            # Read pages file
            pages_csv = File.join(Rails.root, 'resources', 'goldencompass.pdf.pages.csv')
            df = CSV.read(pages_csv, headers: true)

            # Load embeddings file
            embeddings_csv = File.join(Rails.root, 'resources', 'goldencompass.pdf.embeddings.csv')
            document_embeddings = load_embeddings(embeddings_csv)

            # Answer question with context and get answer and context for saving
            answer, context = answer_query_with_context(user_question, df, document_embeddings)

            # Add the answer to the cache for next hour
            cache_answer(user_question, answer)

            # Persist to database
            Question.create(question: user_question, answer: answer)
          end
        end

        voice = get_answer_as_voice(answer)
        render json: { answer: answer, voice: voice }
      end

      private

      def answer_query_with_context(query, df, document_embeddings)
        client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
        prompt, context = construct_prompt(query, document_embeddings, df)

        puts "===\n", prompt

        response = client.completions(
            parameters: {
                prompt: prompt,
                temperature: COMPLETIONS_API_PARAMS['temperature'],
                max_tokens: COMPLETIONS_API_PARAMS['max_tokens'],
                model: COMPLETIONS_API_PARAMS['model']
            }
        )

        return response['choices'][0]['text'].gsub(/^[ \n]+|[ \n]+$/, ''), context
      end

      def cache_answer(question, answer)
        Rails.cache.write(question, answer, expires_in: 1.hour)
      end

      def construct_prompt(question, context_embeddings, df)
          """
          Fetch relevant embeddings
          """
          most_relevant_document_sections = order_document_sections_by_query_similarity(question, context_embeddings)

          chosen_sections = []
          chosen_sections_len = 0
          chosen_sections_indexes = []

          most_relevant_document_sections.each do |_, section_index|
            document_section = find_row_by_title(df, section_index)
            separator_len = 3

            unless document_section.nil?
              tokens = document_section['tokens'].to_i
              content = document_section['content']

              chosen_sections_len += tokens + separator_len
              if chosen_sections_len > MAX_SECTION_LEN
                space_left = MAX_SECTION_LEN - chosen_sections_len - SEPARATOR.length
                chosen_sections.append(SEPARATOR + content[0...space_left])
                chosen_sections_indexes.append(section_index.to_s)
                break
              end
              chosen_sections.append(SEPARATOR + content)
              chosen_sections_indexes.append(section_index.to_s)
            end
          end

          header = """Philip Pullman is the author of the book The Golden Compass (also known as His Dark Materials). Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Golden Compass:\n"""
          question_1 = "\n\n\nQ: Who is Lyra's daemon?\n\nA: Lyra's daemon is Pantalaimon, also known as Pan. He is a shape-shifting creature that takes the form of various animals, but he typically prefers the form of an ermine. He is a constant companion to Lyra."
          question_2 = "\n\n\nQ: Q: What is Tokay?\n\nA: Tokay is a type of sweet dessert wine. It is made from grapes grown in the Tokaj region of Hungary. It is known for its golden color and rich flavor."
          question_3 = "\n\n\nQ: Who tried to poison Lord Asriel?\n\nA: The Master of Jordan College, Dr. Carne, tried to poison Lord Asriel by putting poison in his wine."
          question_4 = "\n\n\nQ: Where does Tony live?\n\nA: Tony lives in Clarice Walk."
          question_5 = "\n\n\nQ: What does the Retiring Room look like?\n\nA: The Retiring Room is a large room with an oval table of polished rosewood, various decanters and glasses, a silver smoking stand with a rack of pipes, a chafing dish, and a basket of poppy heads. The walls are adorned with portraits of old Scholars."
          question_6 = "\n\n\nQ: Who are The Gobblers?\n\nA: The Gobblers are a mysterious group of enchanters who are said to kidnap children and take them away to unknown places."
          question_7 = "\n\n\nQ: What years was Simon Le Clerc master? \n\nA: 1765-1789."
          question_8 = "\n\n\nQ: Who is Ma Costa's daemon?\n\nA: Ma Costa's daemon is a hawk."
          question_9 = "\n\n\nQ: Who is Hugh Lovat?\n\nA: A kitchen boy from St. Michael's."
          question_10 = "\n\n\nQ: Who is Colonel Carborn?\n\nA: Colonel Carborn is an elderly gentleman with a red tie who made the first balloon flight over the North Pole."
          question_11 = "\n\n\nQ: Who is Tony Costa's little brother?\n\nA: Tony Costa's little brother is Billy Costa."

          return (header + chosen_sections.join + question_1 + question_2 + question_3 + question_4 + question_5 + question_6 + question_7 + question_8 + question_9 + question_10 + question_11 + "\n\n\nQ: " + question + "\n\nA: "), (chosen_sections.join)
      end

      def find_row_by_title(csv_table, title)
        csv_table.each do |row|
          return row if row['title'] == title
        end
        nil
      end

      def get_answer_as_voice(answer)
        Resemble.api_key = ENV['RESEMBLE_API_KEY']
        project_uuid = 'b6f4979f'
        voice_uuid = 'd88df2b0'
        # Sync requests are currently disabled
        Resemble::V2::Clip.create_sync(
          project_uuid,
          voice_uuid,
          body: answer,
          title: nil,
          sample_rate: nil,
          output_format: nil,
          precision: nil,
          include_timestamps: nil,
          is_public: nil,
          is_archived: nil,
          raw: nil
        )
      end

      def get_embedding(text)
        client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
        result = client.embeddings(
            parameters: {
                model: DOC_EMBEDDINGS_MODEL_ADA,
                input: text
            }
        )
        result["data"][0]["embedding"]
      end

      def load_embeddings(fname)
        # Read the document embeddings and their keys from a CSV.
        # fname is the path to a CSV with exactly these named columns:
        # "title", "0", "1", ... up to the length of the embedding vectors.
        df = CSV.read(fname, headers: true)
        max_dim = df.headers.reject { |header| header == 'title' }.map(&:to_i).max
        df.each_with_object({}) do |row, h|
          h[row['title']] = (0..max_dim).map { |i| row[i.to_s].to_f }
        end
      end

      def order_document_sections_by_query_similarity(query, contexts)
          """
          Find the query embedding for the supplied query, and compare it against all of the pre-calculated document embeddings
          to find the most relevant sections.
          Return the list of document sections, sorted by relevance in descending order.
          """
          query_embedding = get_embedding(query)

          document_similarities = contexts.map { |doc_index, doc_embedding| [vector_similarity(query_embedding, doc_embedding), doc_index] }.sort.reverse

          return document_similarities
      end

      def vector_similarity(x, y)
        raise ArgumentError, "Input arrays must have the same length" unless x.length == y.length

        dot_product = x.zip(y).map { |x_i, y_i| x_i * y_i }.reduce(:+)
        dot_product
      end
    end
  end
end
