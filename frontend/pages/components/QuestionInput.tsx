import { useState } from 'react';

interface QuestionInputProps {
  clearAnswer: () => void;
  onQuestionChange: (newQuestion: string) => void;
}

const QuestionInput: React.FC<QuestionInputProps> = ({ clearAnswer,onQuestionChange }) => {
  const [question, setQuestion] = useState('');

  const handleChange = (event: React.ChangeEvent<HTMLTextAreaElement>) => {
    clearAnswer();
    const newQuestion = event.target.value;
    setQuestion(newQuestion);
    onQuestionChange(newQuestion);
  };

  return (
    <textarea
      className="border border-gray-300 p-2"
      value={question}
      onChange={handleChange}
      placeholder="Type your question here"
    />
  );
}

export default QuestionInput;