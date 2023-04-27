interface FeelingLuckyButtonProps {
  onClick: (event: React.MouseEvent<HTMLButtonElement>) => void;
  loading: boolean;
}

const FeelingLuckyButton: React.FC<FeelingLuckyButtonProps> = ({ onClick, loading }) => {
  return (
    <button
      className="bg-gray-200 hover:bg-gray-300 border-gray-200 text-gray-500 font-bold py-2 px-4 rounded mx-2"
      onClick={onClick}
      disabled={loading}
    >
      {"Feeling lucky"}
    </button>
  );
}

export default FeelingLuckyButton;