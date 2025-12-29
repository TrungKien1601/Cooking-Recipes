// Table Component
const Table = ({ children, className }) => {
  return <table className={`min-w-full  ${className}`}>{children}</table>;
};

// TableHeader Component
const TableHeader = ({ children, className }) => {
  return <thead className={className}>{children}</thead>;
};

// TableBody Component
const TableBody = ({ children, className }) => {
  return <tbody className={className}>{children}</tbody>;
};

// TableRow Component
const TableRow = ({ children, className, onClick }) => {
  return <tr className={className} onClick={onClick}>{children}</tr>;
};

// TableCell Component
const TableCell = ({ children, isHeader = false, className, ...props }) => {
  const CellTag = isHeader ? "th" : "td";
  return <CellTag className={` ${className}`} { ...props }>{children}</CellTag>;
};

export { Table, TableHeader, TableBody, TableRow, TableCell };
