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
            pages_csv = File.join(Rails.root, 'resources', 'pdf-sample.pdf.pages.csv')
            df = CSV.read(pages_csv, headers: true)

            # Load embeddings file
            embeddings_csv = File.join(Rails.root, 'resources', 'pdf-sample.pdf.embeddings.csv')
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
                chosen_sections.append(SEPARATOR + content[0, space_left])
                chosen_sections_indexes.append(section_index.to_s)
                break
              end

              chosen_sections.append(SEPARATOR + content)
              chosen_sections_indexes.append(section_index.to_s)
            end
          end

          header = """Sahil Lavingia is the founder and CEO of Gumroad, and the author of the book The Minimalist Entrepreneur (also known as TME). These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Minimalist Entrepreneur:\n"""

          question_1 = "\n\n\nQ: How to choose what business to start?\n\nA: First off don't be in a rush. Look around you, see what problems you or other people are facing, and solve one of these problems if you see some overlap with your passions or skills. Or, even if you don't see an overlap, imagine how you would solve that problem anyway. Start super, super small."
          question_2 = "\n\n\nQ: Q: Should we start the business on the side first or should we put full effort right from the start?\n\nA:   Always on the side. Things start small and get bigger from there, and I don't know if I would ever “fully” commit to something unless I had some semblance of customer traction. Like with this product I'm working on now!"
          question_3 = "\n\n\nQ: Should we sell first than build or the other way around?\n\nA: I would recommend building first. Building will teach you a lot, and too many people use “sales” as an excuse to never learn essential skills like building. You can't sell a house you can't build!"
          question_4 = "\n\n\nQ: Andrew Chen has a book on this so maybe touché, but how should founders think about the cold start problem? Businesses are hard to start, and even harder to sustain but the latter is somewhat defined and structured, whereas the former is the vast unknown. Not sure if it's worthy, but this is something I have personally struggled with\n\nA: Hey, this is about my book, not his! I would solve the problem from a single player perspective first. For example, Gumroad is useful to a creator looking to sell something even if no one is currently using the platform. Usage helps, but it's not necessary."
          question_5 = "\n\n\nQ: What is one business that you think is ripe for a minimalist Entrepreneur innovation that isn't currently being pursued by your community?\n\nA: I would move to a place outside of a big city and watch how broken, slow, and non-automated most things are. And of course the big categories like housing, transportation, toys, healthcare, supply chain, food, and more, are constantly being upturned. Go to an industry conference and it's all they talk about! Any industry…"
          question_6 = "\n\n\nQ: How can you tell if your pricing is right? If you are leaving money on the table\n\nA: I would work backwards from the kind of success you want, how many customers you think you can reasonably get to within a few years, and then reverse engineer how much it should be priced to make that work."
          question_7 = "\n\n\nQ: Why is the name of your book 'the minimalist entrepreneur' \n\nA: I think more people should start businesses, and was hoping that making it feel more “minimal” would make it feel more achievable and lead more people to starting-the hardest step."
          question_8 = "\n\n\nQ: How long it takes to write TME\n\nA: About 500 hours over the course of a year or two, including book proposal and outline."
          question_9 = "\n\n\nQ: What is the best way to distribute surveys to test my product idea\n\nA: I use Google Forms and my email list / Twitter account. Works great and is 100% free."
          question_10 = "\n\n\nQ: How do you know, when to quit\n\nA: When I'm bored, no longer learning, not earning enough, getting physically unhealthy, etc… loads of reasons. I think the default should be to “quit” and work on something new. Few things are worth holding your attention for a long period of time."

          return (header + chosen_sections.join + question_1 + question_2 + question_3 + question_4 + question_5 + question_6 + question_7 + question_8 + question_9 + question_10 + "\n\n\nQ: " + question + "\n\nA: "), (chosen_sections.join)
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
