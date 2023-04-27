interface AskQuestionButtonProps {
  onClick: (event: any) => void;
  loading: boolean;
}

const AskQuestionButton: React.FC<AskQuestionButtonProps> = ({ onClick, loading }) => {
  return (
    <button
      className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
      onClick={onClick}
      disabled={loading}
    >
      Ask question
    </button>
  );
}

export default AskQuestionButton;