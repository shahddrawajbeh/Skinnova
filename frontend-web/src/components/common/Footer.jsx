import { Link } from "react-router-dom";
import { Smartphone } from "lucide-react";
import { InstagramIcon, FacebookIcon, XIcon } from "./SocialIcons";

export default function Footer() {
  return (
    <footer className="bg-plum text-white mt-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
        <div>
          <div className="flex items-center gap-2 mb-3">
            <img src="/logo.png" alt="Skinova" className="h-9 w-9 rounded-xl object-cover" />
            <span className="font-display text-xl font-bold">Skinova</span>
          </div>
          <p className="text-white/60 text-sm leading-relaxed">
            Your Skin, Understood. AI-powered skin analysis, personalized routines, and a
            community that gets it.
          </p>
        </div>

        <FooterCol
          title="Explore"
          links={[
            { to: "/scan", label: "AI Skin Scan" },
            { to: "/routine", label: "My Routine" },
            { to: "/shop", label: "Shop" },
            { to: "/community", label: "Community" },
          ]}
        />

        <FooterCol
          title="Account"
          links={[
            { to: "/profile", label: "Profile" },
            { to: "/orders", label: "Orders" },
            { to: "/favorites", label: "Favorites" },
            { to: "/notifications", label: "Notifications" },
          ]}
        />

        <div>
          <h4 className="font-semibold mb-3">Get the app</h4>
          <p className="text-white/60 text-sm mb-3">
            Camera scanning, unlimited AI scans, and the full Skinova experience — only on
            mobile.
          </p>
          <a
            href="#"
            className="inline-flex items-center gap-2 rounded-full bg-gold text-wine-dark px-4 py-2 text-sm font-semibold hover:scale-105 transition-transform"
          >
            <Smartphone size={16} /> Download the app
          </a>
          <div className="flex gap-3 mt-5 text-white/60">
            <InstagramIcon size={18} className="hover:text-dusty-rose transition-colors cursor-pointer" />
            <FacebookIcon size={18} className="hover:text-dusty-rose transition-colors cursor-pointer" />
            <XIcon size={18} className="hover:text-dusty-rose transition-colors cursor-pointer" />
          </div>
        </div>
      </div>
      <div className="border-t border-white/10 py-4 text-center text-xs text-white/50">
        © {new Date().getFullYear()} Skinova. All rights reserved.
      </div>
    </footer>
  );
}

function FooterCol({ title, links }) {
  return (
    <div>
      <h4 className="font-semibold mb-3">{title}</h4>
      <ul className="space-y-2">
        {links.map((l) => (
          <li key={l.to}>
            <Link to={l.to} className="text-white/60 text-sm hover:text-dusty-rose transition-colors">
              {l.label}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
