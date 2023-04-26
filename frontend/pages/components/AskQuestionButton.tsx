interface AskQuestionButtonProps {
  onClick: (event: React.MouseEvent<HTMLButtonElement>) => void;
}

const AskQuestionButton: React.FC<AskQuestionButtonProps> = ({ onClick }) => {
  return (
    <button
      className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
      onClick={onClick}
    >
      Ask question
    </button>
  );
}

export default AskQuestionButton;