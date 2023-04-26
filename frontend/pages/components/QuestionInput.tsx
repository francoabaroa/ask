import { useState } from 'react';

interface QuestionInputProps {
  onQuestionChange: (newQuestion: string) => void;
}

const QuestionInput: React.FC<QuestionInputProps> = ({ onQuestionChange }) => {
  const [question, setQuestion] = useState('');

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newQuestion = event.target.value;
    setQuestion(newQuestion);
    onQuestionChange(newQuestion);
  };

  return (
    <input
      className="border border-gray-300 p-2"
      type="text"
      value={question}
      onChange={handleChange}
      placeholder="Type your question here"
    />
  );
}

export default QuestionInput;