import { Compass } from "lucide-react";
import EmptyState from "../components/common/EmptyState";
import Button from "../components/common/Button";

export default function NotFoundPage() {
  return (
    <div className="min-h-[50vh] flex items-center justify-center">
      <EmptyState
        icon={Compass}
        title="Page not found"
        message="The page you're looking for doesn't exist or has moved."
        action={
          <Button to="/" variant="secondary">
            Back to home
          </Button>
        }
      />
    </div>
  );
}
