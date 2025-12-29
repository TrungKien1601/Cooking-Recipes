// --- COMPONENT HIỂN THỊ TAG (Đã cập nhật màu theo config) ---
const InfoTag = ({ children, color = "gray" }) => {
  // Map màu dựa trên tailwind.config.js
  const colors = {
    gray: "bg-gray-100 text-gray-700 dark:bg-white/10 dark:text-gray-300",
    brand: "bg-brand-50 text-brand-700 border-brand-200 dark:bg-brand-500/10 dark:text-brand-400", // Xanh lá chủ đạo
    red: "bg-error-50 text-error-700 border-error-200 dark:bg-error-500/10 dark:text-error-400",
    orange: "bg-orange-50 text-orange-700 border-orange-200 dark:bg-orange-500/10 dark:text-orange-400",
    blue: "bg-blue-50 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400", // Fallback nếu cần
  };
  
  return (
    <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${colors[color] || colors.gray} border-transparent`}>
      {children}
    </span>
  );
};

export default function InfoBlock ({ label, value, isTag = false, tags = [], tagColor="brand" }) {
  return (
    <div className="flex flex-col gap-1">
        <span className="text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
        {label}
        </span>
        {isTag ? (
        <div className="flex flex-wrap gap-2 mt-1">
            {tags && tags.length > 0 ? (
            tags.map((tag, idx) => (
                <InfoTag key={idx} color={tagColor}>{typeof tag === 'object' ? tag.name || tag : tag}</InfoTag>
            ))
            ) : (
            <span className="text-sm text-gray-400 italic">--</span>
            )}
        </div>
        ) : (
        <span className="text-sm font-medium text-gray-900 dark:text-white/90 break-words">
            {value || "--"}
        </span>
        )}
    </div>
  );
}