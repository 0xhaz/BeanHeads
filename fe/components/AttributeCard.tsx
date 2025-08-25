interface AttributeCardProps {
  title?: string;
  onClose?: () => void;
  children?: React.ReactNode;
  className?: string;
}

const AttributeCard = ({
  title,
  onClose,
  children,
  className,
}: AttributeCardProps) => {
  return (
    <div
      className={`bg-white/10 backdrop-blur-lg border border-white/30 rounded-xl p-6 text-white w-[300px] shadow-lg ${className}`}
      onClick={e => e.stopPropagation()}
    >
      {title && (
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold">{title} </h3>
          {onClose && (
            <button
              onClick={onClose}
              className="text-white/60 hover:text-white cursor-pointer"
            >
              x
            </button>
          )}
        </div>
      )}
      {children}
    </div>
  );
};

export default AttributeCard;
