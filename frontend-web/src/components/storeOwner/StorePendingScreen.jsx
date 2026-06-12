import { Clock, XCircle, StoreIcon, LogOut } from "lucide-react";
import Card from "../common/Card";
import Button from "../common/Button";
import { useAuth } from "../../context/AuthContext";
import { useNavigate } from "react-router-dom";

const STATUS_CONTENT = {
  "no-store": {
    icon: StoreIcon,
    title: "No store found",
    message:
      "We couldn't find a store linked to your account. Please create your store request from the Skinova mobile app to get started.",
  },
  pending: {
    icon: Clock,
    title: "Store pending approval",
    message:
      "Your store request is under review by our team. You'll be able to access your dashboard once it's approved.",
  },
  rejected: {
    icon: XCircle,
    title: "Store request rejected",
    message:
      "Unfortunately your store request was not approved. Please check the reason below or contact support.",
  },
  error: {
    icon: XCircle,
    title: "Something went wrong",
    message: "We couldn't load your store right now. Please try again later.",
  },
};

export default function StorePendingScreen({ status, reason }) {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const content = STATUS_CONTENT[status] || STATUS_CONTENT["no-store"];
  const Icon = content.icon;

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-cream px-4">
      <Card className="max-w-md w-full p-8 text-center animate-pop-in" hover={false}>
        <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-soft-pink text-wine">
          <Icon size={28} />
        </div>
        <h1 className="text-xl font-bold text-ink mb-2">{content.title}</h1>
        <p className="text-sm text-subtext mb-4">{content.message}</p>
        {status === "rejected" && reason && (
          <p className="text-sm text-danger bg-soft-pink rounded-xl p-3 mb-4">
            Reason: {reason}
          </p>
        )}
        <div className="flex flex-col sm:flex-row gap-2 justify-center mt-2">
          <Button to="/" variant="secondary">
            Back to site
          </Button>
          <Button onClick={handleLogout} variant="outline">
            <LogOut size={16} /> Logout
          </Button>
        </div>
      </Card>
    </div>
  );
}
