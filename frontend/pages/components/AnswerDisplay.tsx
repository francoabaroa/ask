interface AnswerDisplayProps {
  answer: string;
}

const AnswerDisplay: React.FC<AnswerDisplayProps> = ({ answer }) => {
  if (answer === '') return null;

  return (
    <div className="border border-gray-300 p-4 mt-4">
      <h3 className="font-bold">Answer:</h3>
      <p>{answer}</p>
    </div>
  );
}

export default AnswerDisplay;