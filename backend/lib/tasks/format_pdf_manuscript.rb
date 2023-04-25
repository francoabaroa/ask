require 'dotenv'
require 'ruby/openai'
require 'pdf-reader'
require 'csv'
require 'tokenizers'

Dotenv.load('.env')

# GPT2 Tokenizer Not Working
# tokenizer = RubyTokenizer::GPT2Tokenizer.new
# tokenizer = Tokenizers.from_pretrained("gpt2")
# tokenizer = Tokenizers::Tokenizer.from_pretrained("gpt2")

COMPLETIONS_MODEL = "text-davinci-003"
MODEL_NAME = "curie"

# use ada cause newer and cheaper
DOC_EMBEDDINGS_MODEL_ADA = "text-embedding-ada-002"

def word_count(text)
  words = text.split
  words.size
end

def count_tokens(text)
  # GPT2 Tokenizer Not Working
  # tokenizer.encode(text).size
  word_count(text)
end

def extract_pages(page_text, index)
  return [] if page_text.empty?
  content = page_text.split.join(' ')
  puts "page text: " + content
  outputs = [["Page #{index}", content, count_tokens(content) + 4]]
  outputs
end

def get_embedding(text, model)
  client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  result = client.embeddings(
      parameters: {
          model: model,
          input: text
      }
  )
  result["data"][0]["embedding"]
end

def get_doc_embedding(text)
  get_embedding(text, DOC_EMBEDDINGS_MODEL_ADA)
end

def compute_doc_embeddings(data)
  data.map.with_index { |row, index| [index, get_doc_embedding(row[1])] }.to_h
end

pdf_filename = ARGV[0] # Pass the PDF file as a command-line argument

reader = PDF::Reader.new(pdf_filename)

res = []
i = 1
reader.pages.each do |page|
  res += extract_pages(page.text, i)
  i += 1
end

# Filter the data based on the 'tokens' value
res.select! { |row| row[2] < 2046 }

# Save the filtered data to a CSV file
CSV.open("#{pdf_filename}.pages.csv", 'w') do |csv|
  csv << ['title', 'content', 'tokens']
  res.each do |row|
    csv << row
  end
end

doc_embeddings = compute_doc_embeddings(res)

CSV.open("#{pdf_filename}.embeddings.csv", "w") do |csv|
  csv << ["title"] + (0..4095).to_a
  doc_embeddings.each do |index, embedding|
    csv << ["Page #{index + 1}"] + embedding
  end
end
