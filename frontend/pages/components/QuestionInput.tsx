import { useState } from 'react';

interface QuestionInputProps {
  clearAnswer: () => void;
  clearLuckyQuestion: () => void;
  feelingLuckyQuestion: string;
  onQuestionChange: (newQuestion: string) => void;
}

const QuestionInput: React.FC<QuestionInputProps> = ({ clearAnswer, clearLuckyQuestion, feelingLuckyQuestion, onQuestionChange }) => {
  const [question, setQuestion] = useState('');
  const handleChange = (event: React.ChangeEvent<HTMLTextAreaElement>) => {
    clearAnswer();
    clearLuckyQuestion();
    const newQuestion = event.target.value;
    setQuestion(newQuestion);
    onQuestionChange(newQuestion);
  };

  return (
    <textarea
      className="border border-gray-300 p-2"
      value={feelingLuckyQuestion.length > 0 ? feelingLuckyQuestion : question}
      onChange={handleChange}
      placeholder="Type your question here"
    />
  );
}

export default QuestionInput;