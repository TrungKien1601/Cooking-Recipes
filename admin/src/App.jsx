import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router";
import SignIn from "./pages/AuthPages/SignIn";
import NotFound from "./pages/OtherPage/NotFound";
import UserProfiles from "./pages/UserProfiles";
import Videos from "./pages/UiElements/Videos";
import Images from "./pages/UiElements/Images";
import Alerts from "./pages/UiElements/Alerts";
import Badges from "./pages/UiElements/Badges";
import Avatars from "./pages/UiElements/Avatars";
import Buttons from "./pages/UiElements/Buttons";
import LineChart from "./pages/Charts/LineChart";
import BarChart from "./pages/Charts/BarChart";
import RecipeTables from "./pages/Tables/Recipes";
import IngreTables from "./pages/Tables/Ingredients";
import TagTables from "./pages/Tables/Tags";
import PantryTables from "./pages/Tables/Pantries";
import UserTables from "./pages/Tables/Users";
import ActivityLog from "./pages/Tables/ActivityLog"
import FormElements from "./pages/Forms/FormElements";
import Blank from "./pages/Blank";
import AppLayout from "./layout/AppLayout";
import { ScrollToTop } from "./components/common/ScrollToTop";
import Home from "./pages/Dashboard/Home";
import ProtectedRoute from "./ProtectedRoute";
import ResetPassword from "./pages/AuthPages/ResetPassword";
import { AuthProvider } from "./hooks/AuthProvider";

export default function App() {
  return (
    <>
      <Router>
        <AuthProvider>
          <ScrollToTop />
          <Routes>
            <Route path="/" element={<Navigate to="/admin/signin"/>} />
            {/* Auth Layout */}
            <Route path="/admin/signin" element={<SignIn />} />
            <Route path="/admin/reset_password" element={<ResetPassword />} />

            {/* Dashboard Layout */}
            <Route path="/admin" element={
              <ProtectedRoute>
                <AppLayout />
              </ProtectedRoute>
              }>
              <Route index element={<Home />} />

              {/* Others Page */}
              <Route path="profile" element={<UserProfiles />} />
              <Route path="blank" element={<Blank />} />

              {/* Tables */}
              <Route path="recipe-tables" element={<RecipeTables />} />
              <Route path="ingredient-tables" element={<IngreTables />} />
              <Route path="tag-tables" element={<TagTables />} />
              <Route path="pantry-tables" element={<PantryTables />} />
              <Route path="user-tables" element={<UserTables />} />
              <Route path="activity-log" element={<ActivityLog />} />

              {/* Ui Elements */}
              <Route path="alerts" element={<Alerts />} />
              <Route path="avatars" element={<Avatars />} />
              <Route path="badge" element={<Badges />} />
              <Route path="buttons" element={<Buttons />} />
              <Route path="images" element={<Images />} />
              <Route path="videos" element={<Videos />} />

              {/* Forms */}
              <Route path="form-elements" element={<FormElements />} />

              {/* Charts */}
              <Route path="line-chart" element={<LineChart />} />
              <Route path="bar-chart" element={<BarChart />} />
            </Route>

            {/* Fallback Route */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </AuthProvider>
      </Router>
    </>
  );
}
