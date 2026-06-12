export default function Card({ children, className = "", hover = true, as: As = "div", ...rest }) {
  return (
    <As
      className={`bg-white rounded-2xl border border-divider shadow-sm transition-all duration-300 ease-out
        ${hover ? "hover:-translate-y-1 hover:shadow-xl hover:shadow-wine/10" : ""}
        ${className}`}
      {...rest}
    >
      {children}
    </As>
  );
}
