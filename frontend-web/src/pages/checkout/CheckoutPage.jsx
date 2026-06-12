import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Loader2, CreditCard, Truck, Wallet, Smartphone, Banknote } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { cartService } from "../../services/cartService";
import { orderService } from "../../services/orderService";
import { formatPrice } from "../../utils/format";

const PAYMENT_METHODS = [
  { value: "cod", label: "Cash on delivery", icon: Truck },
  { value: "card", label: "Credit / debit card", icon: CreditCard },
  { value: "palpay", label: "PalPay", icon: Wallet },
  { value: "reflect", label: "Reflect", icon: Smartphone },
  { value: "apple_pay", label: "Apple Pay", icon: Banknote },
];

const DELIVERY_FEE = 15;

export default function CheckoutPage() {
  const { user, profile } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();

  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const [fullName, setFullName] = useState("");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [city, setCity] = useState("");
  const [streetAddress, setStreetAddress] = useState("");
  const [note, setNote] = useState("");
  const [paymentMethod, setPaymentMethod] = useState("cod");
  const [cardLast4, setCardLast4] = useState("");

  useEffect(() => {
    cartService
      .fetchCart(user.userId)
      .then((data) => setItems(data || []))
      .catch(() => toast.error("Couldn't load your cart."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user.userId]);

  useEffect(() => {
    if (profile?.fullName) setFullName(profile.fullName);
    if (profile?.city) setCity(profile.city);
  }, [profile]);

  const subtotal = items.reduce((sum, it) => sum + it.price * it.quantity, 0);
  const storeCount = new Set(items.map((it) => it.storeId?._id)).size;
  const totalDeliveryFee = DELIVERY_FEE * Math.max(storeCount, 1);
  const total = subtotal + totalDeliveryFee;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!fullName.trim() || !phoneNumber.trim() || !city.trim() || !streetAddress.trim()) {
      toast.error("Please fill in all required fields.");
      return;
    }
    if (paymentMethod === "card" && cardLast4.trim().length !== 4) {
      toast.error("Please enter the last 4 digits of your card.");
      return;
    }

    setSubmitting(true);
    try {
      await orderService.createOrder({
        userId: user.userId,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        city: city.trim(),
        streetAddress: streetAddress.trim(),
        note: note.trim(),
        paymentMethod,
        paymentStatus: paymentMethod === "cod" ? "pending" : "demo_paid",
        cardLast4: paymentMethod === "card" ? cardLast4.trim() : null,
        deliveryFee: DELIVERY_FEE,
      });
      toast.success("Order placed! Track it from your orders page.");
      navigate("/orders");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't place your order.");
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <EmptyState
        icon={Truck}
        title="Your cart is empty"
        message="Add some products before checking out."
        action={
          <Button to="/shop" size="md">
            Go to shop
          </Button>
        }
      />
    );
  }

  return (
    <div className="max-w-4xl mx-auto flex flex-col gap-8 animate-fade-slide-in">
      <h1 className="font-display text-3xl sm:text-4xl font-bold text-ink">Checkout</h1>

      <div className="grid lg:grid-cols-3 gap-8">
        <form onSubmit={handleSubmit} className="lg:col-span-2 flex flex-col gap-6">
          <Card className="p-6 flex flex-col gap-4">
            <h2 className="font-display text-lg font-bold text-ink">Delivery details</h2>
            <div className="grid sm:grid-cols-2 gap-4">
              <input
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                placeholder="Full name"
                required
                className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
              <input
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                placeholder="Phone number"
                required
                className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
              <input
                value={city}
                onChange={(e) => setCity(e.target.value)}
                placeholder="City"
                required
                className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
              <input
                value={streetAddress}
                onChange={(e) => setStreetAddress(e.target.value)}
                placeholder="Street address"
                required
                className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
            </div>
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Delivery notes (optional)"
              rows={2}
              className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all resize-none"
            />
          </Card>

          <Card className="p-6 flex flex-col gap-4">
            <h2 className="font-display text-lg font-bold text-ink">Payment method</h2>
            <div className="grid sm:grid-cols-2 gap-3">
              {PAYMENT_METHODS.map((m) => (
                <button
                  type="button"
                  key={m.value}
                  onClick={() => setPaymentMethod(m.value)}
                  className={`flex items-center gap-3 rounded-2xl border px-4 py-3 text-sm font-semibold transition-all hover:scale-[1.02]
                    ${
                      paymentMethod === m.value
                        ? "border-wine bg-soft-pink text-wine"
                        : "border-divider text-ink hover:border-dusty-rose-light"
                    }`}
                >
                  <m.icon size={18} /> {m.label}
                </button>
              ))}
            </div>
            {paymentMethod === "card" && (
              <input
                value={cardLast4}
                onChange={(e) => setCardLast4(e.target.value.replace(/\D/g, "").slice(0, 4))}
                placeholder="Last 4 digits of card"
                maxLength={4}
                required
                className="w-full sm:w-48 rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
            )}
          </Card>

          <Button type="submit" disabled={submitting} size="lg" className="self-stretch sm:self-start">
            {submitting ? <Loader2 size={18} className="animate-spin" /> : null}
            Place order
          </Button>
        </form>

        <Card className="p-6 h-fit flex flex-col gap-3">
          <h2 className="font-display text-lg font-bold text-ink">Order summary</h2>
          <div className="flex flex-col gap-2 max-h-64 overflow-y-auto pr-1">
            {items.map((item) => (
              <div key={`${item.productId?._id}_${item.storeId?._id}`} className="flex justify-between text-sm">
                <span className="text-ink line-clamp-1 pr-2">
                  {item.quantity}× {item.productId?.name}
                </span>
                <span className="text-subtext shrink-0">{formatPrice(item.price * item.quantity, item.currency)}</span>
              </div>
            ))}
          </div>
          <div className="h-px bg-divider my-1" />
          <div className="flex justify-between text-sm text-subtext">
            <span>Subtotal</span>
            <span>{formatPrice(subtotal, items[0]?.currency)}</span>
          </div>
          <div className="flex justify-between text-sm text-subtext">
            <span>Delivery ({storeCount} store{storeCount === 1 ? "" : "s"})</span>
            <span>{formatPrice(totalDeliveryFee, items[0]?.currency)}</span>
          </div>
          <div className="h-px bg-divider my-1" />
          <div className="flex justify-between font-bold text-ink">
            <span>Total</span>
            <span className="text-wine">{formatPrice(total, items[0]?.currency)}</span>
          </div>
        </Card>
      </div>
    </div>
  );
}
