import { Link } from "react-router-dom";

const variants = {
  primary:
    "bg-wine text-white hover:bg-wine-dark shadow-md shadow-wine/20 hover:shadow-lg hover:shadow-wine/30",
  secondary:
    "bg-soft-pink text-wine hover:bg-dusty-rose-light border border-dusty-rose-light",
  outline:
    "bg-transparent text-wine border-2 border-wine hover:bg-wine hover:text-white",
  ghost: "bg-transparent text-wine hover:bg-soft-pink",
  gold: "bg-gold text-wine-dark hover:brightness-105 shadow-md shadow-gold/30",
};

const sizes = {
  sm: "px-4 py-2 text-sm",
  md: "px-6 py-2.5 text-sm",
  lg: "px-8 py-3.5 text-base",
};

export default function Button({
  children,
  variant = "primary",
  size = "md",
  to,
  href,
  className = "",
  disabled = false,
  type = "button",
  ...rest
}) {
  const classes = `inline-flex items-center justify-center gap-2 rounded-full font-semibold tracking-wide
    transition-all duration-200 ease-out hover:scale-[1.03] active:scale-[0.98]
    disabled:opacity-50 disabled:pointer-events-none disabled:hover:scale-100
    ${variants[variant] || variants.primary} ${sizes[size] || sizes.md} ${className}`;

  if (to) {
    return (
      <Link to={to} className={classes} {...rest}>
        {children}
      </Link>
    );
  }
  if (href) {
    return (
      <a href={href} className={classes} {...rest}>
        {children}
      </a>
    );
  }
  return (
    <button type={type} className={classes} disabled={disabled} {...rest}>
      {children}
    </button>
  );
}
