import { Routes, Route } from "react-router-dom";
import MainLayout from "../layouts/MainLayout";
import StoreOwnerLayout from "../layouts/StoreOwnerLayout";
import ProtectedRoute from "../components/common/ProtectedRoute";
import HomePage from "../pages/HomePage";
import LoginPage from "../pages/auth/LoginPage";
import RegisterPage from "../pages/auth/RegisterPage";
import OnboardingPage from "../pages/auth/OnboardingPage";
import ScanPage from "../pages/scan/ScanPage";
import ScanResultsPage from "../pages/scan/ScanResultsPage";
import RoutinePage from "../pages/routine/RoutinePage";
import ShopPage from "../pages/shop/ShopPage";
import ProductDetailsPage from "../pages/shop/ProductDetailsPage";
import StoreProfilePage from "../pages/shop/StoreProfilePage";
import CartPage from "../pages/cart/CartPage";
import CheckoutPage from "../pages/checkout/CheckoutPage";
import OrdersPage from "../pages/orders/OrdersPage";
import OrderDetailPage from "../pages/orders/OrderDetailPage";
import FavoritesPage from "../pages/favorites/FavoritesPage";
import CommunityPage from "../pages/community/CommunityPage";
import GroupPage from "../pages/community/GroupPage";
import ProfilePage from "../pages/profile/ProfilePage";
import NotificationsPage from "../pages/notifications/NotificationsPage";
import NotFoundPage from "../pages/NotFoundPage";
import StoreOwnerDashboardPage from "../pages/storeOwner/DashboardPage";
import StoreOwnerProductsPage from "../pages/storeOwner/ProductsPage";
import StoreOwnerOrdersPage from "../pages/storeOwner/OrdersPage";
import StoreOwnerOrderDetailPage from "../pages/storeOwner/OrderDetailPage";
import StoreOwnerAnalyticsPage from "../pages/storeOwner/AnalyticsPage";
import StoreOwnerReviewsPage from "../pages/storeOwner/ReviewsPage";
import StoreOwnerCommunityPage from "../pages/storeOwner/CommunityPage";
import StoreOwnerStoreProfilePage from "../pages/storeOwner/StoreProfilePage";
import StoreOwnerNotificationsPage from "../pages/storeOwner/NotificationsPage";
import StoreOwnerSettingsPage from "../pages/storeOwner/SettingsPage";
import AdminLayout from "../layouts/AdminLayout";
import AdminDashboardPage from "../pages/admin/DashboardPage";
import AdminUsersPage from "../pages/admin/UsersPage";
import AdminStoresPage from "../pages/admin/StoresPage";
import AdminStoreRequestsPage from "../pages/admin/StoreRequestsPage";
import AdminProductsPage from "../pages/admin/ProductsPage";
import AdminOrdersPage from "../pages/admin/OrdersPage";
import AdminOrderDetailPage from "../pages/admin/OrderDetailPage";
import AdminAnalyticsPage from "../pages/admin/AnalyticsPage";
import AdminReportsPage from "../pages/admin/ReportsPage";
import AdminNotificationsPage from "../pages/admin/NotificationsPage";
import AdminSupportPage from "../pages/admin/SupportPage";
import AdminSettingsPage from "../pages/admin/SettingsPage";

export default function AppRoutes() {
  return (
    <Routes>
      <Route element={<MainLayout />}>
        <Route index element={<HomePage />} />
        <Route path="login" element={<LoginPage />} />
        <Route path="register" element={<RegisterPage />} />
        <Route
          path="onboarding"
          element={
            <ProtectedRoute>
              <OnboardingPage />
            </ProtectedRoute>
          }
        />

        <Route
          path="scan"
          element={
            <ProtectedRoute>
              <ScanPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="scan/results"
          element={
            <ProtectedRoute>
              <ScanResultsPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="routine"
          element={
            <ProtectedRoute>
              <RoutinePage />
            </ProtectedRoute>
          }
        />

        <Route path="shop" element={<ShopPage />} />
        <Route path="shop/product/:id" element={<ProductDetailsPage />} />
        <Route path="shop/store/:id" element={<StoreProfilePage />} />
        <Route
          path="cart"
          element={
            <ProtectedRoute>
              <CartPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="checkout"
          element={
            <ProtectedRoute>
              <CheckoutPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="orders"
          element={
            <ProtectedRoute>
              <OrdersPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="orders/:id"
          element={
            <ProtectedRoute>
              <OrderDetailPage />
            </ProtectedRoute>
          }
        />

        <Route path="community" element={<CommunityPage />} />
        <Route path="community/group/:slug" element={<GroupPage />} />

        <Route
          path="profile"
          element={
            <ProtectedRoute>
              <ProfilePage />
            </ProtectedRoute>
          }
        />
        <Route
          path="favorites"
          element={
            <ProtectedRoute>
              <FavoritesPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="notifications"
          element={
            <ProtectedRoute>
              <NotificationsPage />
            </ProtectedRoute>
          }
        />

        <Route path="*" element={<NotFoundPage />} />
      </Route>

      <Route
        path="store-owner"
        element={
          <ProtectedRoute allowedRoles={["seller"]}>
            <StoreOwnerLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<StoreOwnerDashboardPage />} />
        <Route path="products" element={<StoreOwnerProductsPage />} />
        <Route path="orders" element={<StoreOwnerOrdersPage />} />
        <Route path="orders/:id" element={<StoreOwnerOrderDetailPage />} />
        <Route path="analytics" element={<StoreOwnerAnalyticsPage />} />
        <Route path="reviews" element={<StoreOwnerReviewsPage />} />
        <Route path="community" element={<StoreOwnerCommunityPage />} />
        <Route path="store-profile" element={<StoreOwnerStoreProfilePage />} />
        <Route path="notifications" element={<StoreOwnerNotificationsPage />} />
        <Route path="settings" element={<StoreOwnerSettingsPage />} />
      </Route>

      <Route
        path="admin"
        element={
          <ProtectedRoute allowedRoles={["admin"]}>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<AdminDashboardPage />} />
        <Route path="users" element={<AdminUsersPage />} />
        <Route path="stores" element={<AdminStoresPage />} />
        <Route path="store-requests" element={<AdminStoreRequestsPage />} />
        <Route path="products" element={<AdminProductsPage />} />
        <Route path="orders" element={<AdminOrdersPage />} />
        <Route path="orders/:id" element={<AdminOrderDetailPage />} />
        <Route path="analytics" element={<AdminAnalyticsPage />} />
        <Route path="reports" element={<AdminReportsPage />} />
        <Route path="notifications" element={<AdminNotificationsPage />} />
        <Route path="support" element={<AdminSupportPage />} />
        <Route path="settings" element={<AdminSettingsPage />} />
      </Route>
    </Routes>
  );
}
