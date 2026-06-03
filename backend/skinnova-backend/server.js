const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
require("dotenv").config();
console.log("EMAIL_USER =", process.env.EMAIL_USER);
console.log("EMAIL_PASS exists =", !!process.env.EMAIL_PASS);
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*", methods: ["GET", "POST", "PUT"] },
});
app.set("io", io);

// ── Firebase Admin SDK (push notifications) ─────────────────────────────────
const { initFirebase } = require("./services/firebase");
initFirebase();

// ── Notification reminder cron jobs ─────────────────────────────────────────
const { initReminderJobs } = require("./jobs/notificationReminderJobs");

app.use(cors());
app.use(express.json());

mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB connected");
    initReminderJobs();
  })
  .catch((err) => console.log("Mongo error:", err));

app.get("/", (req, res) => {
  res.send("API is working");
});

const path = require("path");
app.use("/uploads", express.static(path.join(__dirname, "uploads")));
app.use("/uploads/verification-docs", express.static(path.join(__dirname, "uploads/verification-docs")));

// ── Public settings (before maintenance check so app can always read them) ──
app.use("/api/settings", require("./routes/settings"));

// ── Maintenance mode — blocks non-admin routes when enabled ─────────────────
const maintenanceMiddleware = require("./middleware/maintenanceMiddleware");
app.use(maintenanceMiddleware);

const authRoutes = require("./routes/auth");
const productsRoutes = require("./routes/products");
const favoriteRoutes = require("./routes/favorites");
const cartRoutes = require("./routes/cart");
const orderRoutes = require("./routes/orders");
const groupRoutes = require("./routes/group");
const groupPostsRoutes = require("./routes/group_posts");
const skinScanRoutes = require("./routes/skinScanRoutes");
const storeRoutes = require("./routes/stores");
const storeProductRoutes = require("./routes/storeProducts");

app.use("/api/auth", authRoutes);
app.use("/api/products", productsRoutes);
app.use("/api/favorites", favoriteRoutes);
app.use("/api/cart", cartRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/groups", groupRoutes);
app.use("/api/group-posts", groupPostsRoutes);
app.use("/uploads", express.static("uploads"));
app.use("/api/ingredients", require("./routes/ingredientRoutes"));
app.use("/api/medications", require("./routes/medicationRoutes"));
const productScanRoutes = require("./routes/productScanRoutes");
app.use("/api/product-scan", productScanRoutes);
const adRoutes = require("./routes/adRoutes");
app.use("/api/ads", adRoutes);
app.use("/api/skin-scan", skinScanRoutes);
app.use("/api/stores", storeRoutes);
app.use("/api/store-products", storeProductRoutes);
const routineRoutes = require("./routes/routineRoutes");
app.use("/api/routines", routineRoutes);
const storeReportRoutes = require("./routes/storeReports");
app.use("/api/store-reports", storeReportRoutes);
const notificationRoutes = require("./routes/notifications");
app.use("/api/notifications", notificationRoutes);
const chatRoutes = require("./routes/chat");
app.use("/api/chat", chatRoutes);
const supportRoutes = require("./routes/support");
app.use("/api/support", supportRoutes);
const shopAiRoutes = require("./routes/shopAiRoutes");
app.use("/api/shop-ai", shopAiRoutes);
const tryBeforeBuyRoutes = require("./routes/tryBeforeBuyRoutes");
app.use("/api/try-before-buy", tryBeforeBuyRoutes);

// ── Admin Routes ────────────────────────────────────────────────────────────
app.use("/api/admin/stats", require("./routes/admin/adminStats"));
app.use("/api/admin/admins", require("./routes/admin/adminAdmins"));
app.use("/api/admin/users", require("./routes/admin/adminUsers"));
app.use("/api/admin/stores", require("./routes/admin/adminStores"));
app.use("/api/admin/products", require("./routes/admin/adminProducts"));
app.use("/api/admin/ads", require("./routes/admin/adminAds"));
app.use("/api/admin/home-settings", require("./routes/admin/adminHomeSettings"));
app.use("/api/admin/groups", require("./routes/admin/adminGroups"));
app.use("/api/admin/group-posts", require("./routes/admin/adminGroupPosts"));
app.use("/api/admin/orders", require("./routes/admin/adminOrders"));
app.use("/api/admin/reviews", require("./routes/admin/adminReviews"));
app.use("/api/admin/notifications", require("./routes/admin/adminNotifications"));
app.use("/api/admin/settings", require("./routes/admin/adminSettings"));
app.use("/api/admin/welcome-settings", require("./routes/admin/adminWelcomeSettings"));
app.use("/api/admin/analytics", require("./routes/admin/adminAnalytics"));
app.use("/api/product-usage-reminders", require("./routes/productUsageReminderRoutes"));
app.use("/api/ai", require("./routes/productSuitabilityRoutes"));

// ── Socket.IO ─────────────────────────────────────────────────────────────────
io.on("connection", (socket) => {
  socket.on("join_conversation", (conversationId) => {
    socket.join(conversationId);
  });

  socket.on("leave_conversation", (conversationId) => {
    socket.leave(conversationId);
  });

  socket.on("join_seller_room", (sellerId) => {
    socket.join(`seller_${sellerId}`);
  });

  socket.on("leave_seller_room", (sellerId) => {
    socket.leave(`seller_${sellerId}`);
  });

  // Relay message to the other participant in the room
  socket.on("send_message", (data) => {
    socket.to(data.conversationId).emit("new_message", data);
  });

  socket.on("typing", (data) => {
    socket
      .to(data.conversationId)
      .emit("user_typing", { senderId: data.senderId });
  });

  socket.on("stop_typing", (data) => {
    socket
      .to(data.conversationId)
      .emit("user_stop_typing", { senderId: data.senderId });
  });

  socket.on("message_seen", (data) => {
    socket.to(data.conversationId).emit("messages_seen", data);
  });
});

server.listen(5000, "0.0.0.0", () => {
  console.log("Server running on port 5000");
});
