import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:turf_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/logo_animation_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/onboarding2_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/onboarding3_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/welcome_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/login_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/language_selection_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/theme_selection_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/location_access_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/data_privacy_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/account_security_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/delete_account_screen.dart';

import 'package:turf_app/features/home/presentation/screens/home_screen.dart';
import 'package:turf_app/features/home/presentation/screens/discover_screen.dart';
import 'package:turf_app/features/home/presentation/screens/search_screen.dart';
import 'package:turf_app/features/home/presentation/screens/search_results_screen.dart';
import 'package:turf_app/features/home/presentation/screens/categories_screen.dart';
import 'package:turf_app/features/home/presentation/screens/nearby_turfs_screen.dart';
import 'package:turf_app/features/home/presentation/screens/popular_turfs_screen.dart';
import 'package:turf_app/features/home/presentation/screens/featured_turfs_screen.dart';
import 'package:turf_app/features/home/presentation/screens/ai_recommendations_screen.dart';
import 'package:turf_app/features/home/presentation/screens/notifications_screen.dart';
import 'package:turf_app/features/home/presentation/screens/search_filters_screen.dart';
import 'package:turf_app/features/home/presentation/screens/match_scoreboard_screen.dart';
import 'package:turf_app/features/home/presentation/screens/scoreboard_setup_screen.dart';
import 'package:turf_app/features/home/presentation/screens/peak_hours_screen.dart';
import 'package:turf_app/features/home/presentation/screens/offers_promotions_screen.dart';
import 'package:turf_app/features/home/presentation/screens/map_view_screen.dart';
import 'package:turf_app/features/home/presentation/screens/join_match_screen.dart';
import 'package:turf_app/features/home/presentation/screens/match_details_screen.dart';
import 'package:turf_app/features/home/presentation/screens/create_match_screen.dart';
import 'package:turf_app/features/home/presentation/screens/invite_players_screen.dart';
import 'package:turf_app/features/home/presentation/screens/match_timeline_screen.dart';
import 'package:turf_app/features/home/presentation/screens/mvp_screen.dart';
import 'package:turf_app/features/home/presentation/screens/match_summary_screen.dart';
import 'package:turf_app/features/home/presentation/screens/player_performance_screen.dart';
import 'package:turf_app/features/home/presentation/screens/share_match_screen.dart';
import 'package:turf_app/features/home/presentation/screens/match_history_screen.dart';
import 'package:turf_app/features/home/presentation/screens/match_reminders_screen.dart';
import 'package:turf_app/features/home/presentation/screens/active_matches_screen.dart';
import 'package:turf_app/features/home/presentation/screens/my_matches_screen.dart';
import 'package:turf_app/features/booking/domain/models/booking.dart';

import 'package:turf_app/features/turf_details/presentation/screens/turf_details_screen.dart';
import 'package:turf_app/features/turf_details/presentation/screens/turf_gallery_screen.dart';
import 'package:turf_app/features/turf_details/presentation/screens/amenities_screen.dart';
import 'package:turf_app/features/turf_details/presentation/screens/reviews_screen.dart';
import 'package:turf_app/features/turf_details/presentation/screens/available_sports_screen.dart';
import 'package:turf_app/features/turf_details/presentation/screens/similar_turfs_screen.dart';
import 'package:turf_app/features/turf_details/presentation/screens/save_turf_confirmation_screen.dart';
import 'package:turf_app/features/turf_details/presentation/screens/ai_slot_recommendation_screen.dart';
import 'package:turf_app/features/turf_details/presentation/screens/slot_selection_screen.dart';

import 'package:turf_app/features/booking/presentation/screens/select_duration_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/select_players_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/add_extras_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/promo_code_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/checkout_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/payment_options_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/booking_success_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/booking_confirmation_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/qr_entry_pass_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/booking_details_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/my_bookings_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/cancel_booking_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/rebook_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/add_to_calendar_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/checkin_qr_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/review_rating_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/share_booking_screen.dart';

import 'package:turf_app/features/team/presentation/screens/team_dashboard_screen.dart';
import 'package:turf_app/features/team/presentation/screens/team_management_screen.dart';
import 'package:turf_app/features/team/presentation/screens/team_profile_screen.dart';
import 'package:turf_app/features/team/presentation/screens/invite_members_screen.dart';
import 'package:turf_app/features/team/presentation/screens/player_list_screen.dart';
import 'package:turf_app/features/team/presentation/screens/team_ranking_screen.dart';
import 'package:turf_app/features/team/presentation/screens/team_statistics_screen.dart';
import 'package:turf_app/features/team/presentation/screens/team_schedule_screen.dart';
import 'package:turf_app/features/team/presentation/screens/team_settings_screen.dart';

import 'package:turf_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/ai_player_rating_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/achievements_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/badges_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/player_stats_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/favorite_sports_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/skill_level_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/preferences_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/player_leaderboard_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/favorites_screen.dart';
import 'package:turf_app/features/profile/presentation/screens/career_screen.dart';

import 'package:turf_app/features/chat/presentation/screens/team_chat_screen.dart';
import 'package:turf_app/features/chat/presentation/screens/in_app_messages_screen.dart';
import 'package:turf_app/features/chat/presentation/screens/friend_chat_screen.dart';

import 'package:turf_app/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:turf_app/features/wallet/presentation/screens/transactions_screen.dart';
import 'package:turf_app/features/wallet/presentation/screens/bys_coins_screen.dart';

import 'package:turf_app/features/referral/presentation/screens/referral_screen.dart';
import 'package:turf_app/features/referral/presentation/screens/referral_history_screen.dart';

import 'package:turf_app/features/support/presentation/screens/support_center_screen.dart';
import 'package:turf_app/features/support/presentation/screens/faqs_screen.dart';
import 'package:turf_app/features/support/presentation/screens/terms_conditions_screen.dart';
import 'package:turf_app/features/support/presentation/screens/about_us_screen.dart';
import 'package:turf_app/features/support/presentation/screens/logout_confirmation_screen.dart';

import 'package:turf_app/features/admin/presentation/screens/analytics_dashboard_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/venue_calendar_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/venue_earnings_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/venue_reviews_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/venue_settings_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/addons_management_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/live_booking_requests_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/turf_owner_dashboard_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/add_turf_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/manage_users_screen.dart';

import 'package:turf_app/features/stats/presentation/screens/match_stats_screen.dart';
import 'package:turf_app/features/tournament/presentation/screens/tournaments_list_screen.dart';
import 'package:turf_app/features/tournament/presentation/screens/tournament_hub_screen.dart';
import 'package:turf_app/features/tournament/presentation/screens/create_tournament_screen.dart';
import 'package:turf_app/features/tournament/presentation/screens/tournament_register_screen.dart';
import 'package:turf_app/features/tournament/presentation/screens/tournament_rules_screen.dart';
import 'package:turf_app/features/community/presentation/screens/community_feed_screen.dart';
import 'package:turf_app/features/coach/presentation/screens/coach_booking_screen.dart';
import 'package:turf_app/features/store/presentation/screens/store_screen.dart';
import 'package:turf_app/features/stocks/presentation/screens/stock_shares_screen.dart';
import 'package:turf_app/features/weather/presentation/screens/weather_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // 1. Logo / Splash / Onboarding
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/logo-animation', builder: (context, state) => const LogoAnimationScreen()),
      GoRoute(path: '/onboarding1', redirect: (context, state) => '/login'),
      GoRoute(path: '/onboarding2', builder: (context, state) => const Onboarding2Screen()),
      GoRoute(path: '/onboarding3', builder: (context, state) => const Onboarding3Screen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/otp-verification', builder: (context, state) => OtpVerificationScreen(phoneNumber: (state.extra as String?) ?? '+91 98765 43210')),
      GoRoute(path: '/language-selection', builder: (context, state) => const LanguageSelectionScreen()),
      GoRoute(path: '/theme-selection', builder: (context, state) => const ThemeSelectionScreen()),
      GoRoute(path: '/location-access', builder: (context, state) => const LocationAccessScreen()),
      GoRoute(path: '/data-privacy', builder: (context, state) => const DataPrivacyScreen()),
      GoRoute(path: '/account-security', builder: (context, state) => const AccountSecurityScreen()),
      GoRoute(path: '/delete-account', builder: (context, state) => const DeleteAccountScreen()),

      // 2. Home & Discovery
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(path: '/search-results', builder: (context, state) => SearchResultsScreen(query: state.uri.queryParameters['query'] ?? '')),
      GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen()),
      GoRoute(path: '/nearby-turfs', builder: (context, state) => const NearbyTurfsScreen()),
      GoRoute(path: '/map-view', builder: (context, state) => const MapViewScreen()),
      GoRoute(path: '/popular-turfs', builder: (context, state) => const PopularTurfsScreen()),
      GoRoute(path: '/featured-turfs', builder: (context, state) => const FeaturedTurfsScreen()),
      GoRoute(path: '/ai-recommendations', builder: (context, state) => const AiRecommendationsScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/discover', builder: (context, state) => const DiscoverTurfScreen()),
      GoRoute(path: '/search-filters', builder: (context, state) => const SearchFiltersScreen()),
      GoRoute(path: '/peak-hours', builder: (context, state) => const PeakHoursScreen()),
      GoRoute(path: '/offers-promotions', builder: (context, state) => const OffersPromotionsScreen()),

      // 3. Turf Details
      GoRoute(path: '/turf-details/:id', builder: (context, state) => TurfDetailsScreen(turfId: state.pathParameters['id']!)),
      GoRoute(path: '/turf-gallery/:id', builder: (context, state) => TurfGalleryScreen(turfId: state.pathParameters['id']!)),
      GoRoute(path: '/amenities/:id', builder: (context, state) => AmenitiesScreen(turfId: state.pathParameters['id']!)),
      GoRoute(path: '/reviews/:id', builder: (context, state) => ReviewsScreen(turfId: state.pathParameters['id']!)),
      GoRoute(path: '/available-sports/:id', builder: (context, state) => AvailableSportsScreen(turfId: state.pathParameters['id']!)),
      GoRoute(path: '/similar-turfs/:id', builder: (context, state) => SimilarTurfsScreen(turfId: state.pathParameters['id']!)),
      GoRoute(path: '/save-turf-confirm', builder: (context, state) => const SaveTurfConfirmationScreen()),
      GoRoute(path: '/ai-slot-recommendation', builder: (context, state) => const AiSlotRecommendationScreen()),
      GoRoute(path: '/slot-selection/:id', builder: (context, state) => SlotSelectionScreen(turfId: state.pathParameters['id']!)),

      // 4. Booking & Checkout
      GoRoute(path: '/select-duration', builder: (context, state) => const SelectDurationScreen()),
      GoRoute(path: '/select-players', builder: (context, state) => const SelectPlayersScreen()),
      GoRoute(path: '/add-extras', builder: (context, state) => const AddExtrasScreen()),
      GoRoute(path: '/promo-code', builder: (context, state) => const PromoCodeScreen()),
      GoRoute(path: '/checkout', builder: (context, state) => CheckoutScreen(data: state.extra as Map<String, dynamic>?)),
      GoRoute(path: '/payment', builder: (context, state) => PaymentOptionsScreen(data: state.extra as Map<String, dynamic>?)),
      GoRoute(path: '/booking-success', builder: (context, state) => BookingSuccessScreen(data: state.extra as Map<String, dynamic>?)),
      GoRoute(path: '/booking-confirmation', builder: (context, state) => const BookingConfirmationScreen()),
      GoRoute(path: '/qr-entry-pass', builder: (context, state) => const QrEntryPassScreen()),
      GoRoute(
        path: '/booking-details/:id',
        builder: (context, state) => BookingDetailsScreen(
          bookingId: state.pathParameters['id']!,
          booking: state.extra as Booking?,
        ),
      ),
      GoRoute(path: '/my-bookings', builder: (context, state) => const MyBookingsScreen()),
      GoRoute(path: '/cancel-booking/:id', builder: (context, state) => CancelBookingScreen(bookingId: state.pathParameters['id']!)),
      GoRoute(path: '/rebook/:id', builder: (context, state) => RebookScreen(bookingId: state.pathParameters['id']!)),
      GoRoute(path: '/add-to-calendar', builder: (context, state) => const AddToCalendarScreen()),
      GoRoute(path: '/checkin-qr', builder: (context, state) => const CheckInQrScreen()),
      GoRoute(path: '/review-rating', builder: (context, state) => const ReviewRatingScreen()),
      GoRoute(path: '/share-booking', builder: (context, state) => const ShareBookingScreen()),

      // 5. Matches & Live Scoreboard
      GoRoute(path: '/my-matches', builder: (context, state) => const MyMatchesScreen()),
      GoRoute(path: '/matches', builder: (context, state) => const MyMatchesScreen()),
      GoRoute(path: '/join-match', builder: (context, state) => const JoinMatchScreen()),
      GoRoute(path: '/join-turf', builder: (context, state) => const JoinMatchScreen()),
      GoRoute(path: '/active-matches', builder: (context, state) => const ActiveMatchesScreen()),
      GoRoute(path: '/live-matches', builder: (context, state) => const ActiveMatchesScreen()),
      GoRoute(path: '/match-details/:id', builder: (context, state) => MatchDetailsScreen(matchId: state.pathParameters['id']!)),
      GoRoute(path: '/create-match', builder: (context, state) => const CreateMatchScreen()),
      GoRoute(path: '/invite-players', builder: (context, state) => const InvitePlayersScreen()),
      GoRoute(
        path: '/scoreboard-setup',
        builder: (context, state) {
          Map<String, dynamic>? config;
          if (state.extra != null && state.extra is Map) {
            config = Map<String, dynamic>.from(state.extra as Map);
          }
          return ScoreboardSetupScreen(
            initialConfig: config,
          );
        },
      ),
      GoRoute(
        path: '/scoreboard',
        builder: (context, state) {
          Map<String, dynamic>? config;
          if (state.extra != null && state.extra is Map) {
            config = Map<String, dynamic>.from(state.extra as Map);
          }
          return MatchScoreboardScreen(
            initialConfig: config,
          );
        },
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) {
          Map<String, dynamic>? matchData;
          if (state.extra != null && state.extra is Map) {
            matchData = Map<String, dynamic>.from(state.extra as Map);
          }
          return MatchStatsScreen(matchData: matchData);
        },
      ),
      GoRoute(
        path: '/match-stats/:id',
        builder: (context, state) {
          Map<String, dynamic>? matchData;
          if (state.extra != null && state.extra is Map) {
            matchData = Map<String, dynamic>.from(state.extra as Map);
          }
          return MatchStatsScreen(
            matchId: state.pathParameters['id'],
            matchData: matchData,
          );
        },
      ),
      GoRoute(path: '/match-timeline/:id', builder: (context, state) => MatchTimelineScreen(matchId: state.pathParameters['id']!)),
      GoRoute(path: '/mvp-screen', builder: (context, state) => const MvpScreen()),
      GoRoute(path: '/match-summary/:id', builder: (context, state) => MatchSummaryScreen(matchId: state.pathParameters['id']!)),
      GoRoute(path: '/player-performance/:id', builder: (context, state) => PlayerPerformanceScreen(matchId: state.pathParameters['id']!)),
      GoRoute(path: '/share-match/:id', builder: (context, state) => ShareMatchScreen(matchId: state.pathParameters['id']!)),
      GoRoute(path: '/match-history', builder: (context, state) => const MatchHistoryScreen()),
      GoRoute(path: '/match-reminders', builder: (context, state) => const MatchRemindersScreen()),

      // 6. Teams & Tournaments
      GoRoute(path: '/team-dashboard', builder: (context, state) => const TeamDashboardScreen()),
      GoRoute(path: '/team-management', builder: (context, state) => const TeamManagementScreen()),
      GoRoute(path: '/team-profile', builder: (context, state) => const TeamProfileScreen()),
      GoRoute(path: '/invite-members', builder: (context, state) => const InviteMembersScreen()),
      GoRoute(path: '/player-list', builder: (context, state) => const PlayerListScreen()),
      GoRoute(path: '/team-ranking', builder: (context, state) => const TeamRankingScreen()),
      GoRoute(path: '/team-statistics', builder: (context, state) => const TeamStatisticsScreen()),
      GoRoute(path: '/team-schedule', builder: (context, state) => const TeamScheduleScreen()),
      GoRoute(path: '/team-settings', builder: (context, state) => const TeamSettingsScreen()),
      GoRoute(path: '/tournaments', builder: (context, state) => const TournamentsListScreen()),
      GoRoute(path: '/create-tournament', builder: (context, state) => const CreateTournamentScreen()),
      GoRoute(
        path: '/tournament-hub',
        builder: (context, state) => TournamentHubScreen(
          tournamentData: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/tournament-details/:id',
        builder: (context, state) => TournamentHubScreen(
          tournamentData: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/tournament-register',
        builder: (context, state) => TournamentRegisterScreen(
          tournament: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/tournament-rules',
        builder: (context, state) => TournamentRulesScreen(
          data: state.extra as Map<String, dynamic>?,
        ),
      ),

      // 7. Profile & Personal Stats
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/career', builder: (context, state) => const CareerScreen()),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/ai-player-rating', builder: (context, state) => const AiPlayerRatingScreen()),
      GoRoute(path: '/achievements', builder: (context, state) => const AchievementsScreen()),
      GoRoute(path: '/badges', builder: (context, state) => const BadgesScreen()),
      GoRoute(path: '/player-stats', builder: (context, state) => const PlayerStatsScreen()),
      GoRoute(path: '/favorite-sports', builder: (context, state) => const FavoriteSportsScreen()),
      GoRoute(path: '/skill-level', builder: (context, state) => const SkillLevelScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/preferences', builder: (context, state) => const PreferencesScreen()),
      GoRoute(path: '/player-leaderboard', builder: (context, state) => const PlayerLeaderboardScreen()),
      GoRoute(path: '/wishlist', builder: (context, state) => const FavoritesScreen()),
      GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),

      // 8. Communication & Support
      GoRoute(path: '/chat', builder: (context, state) => const TeamChatScreen()),
      GoRoute(path: '/messages', builder: (context, state) => const InAppMessagesScreen()),
      GoRoute(
        path: '/friend-chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FriendChatScreen(
            friendName: extra?['name'] as String? ?? 'Player',
            friendAvatar: extra?['avatar'] as String?,
            friendStatus: extra?['status'] as String? ?? 'Online',
          );
        },
      ),
      GoRoute(path: '/wallet', builder: (context, state) => const WalletScreen()),
      GoRoute(path: '/transactions', builder: (context, state) => const TransactionsScreen()),
      GoRoute(path: '/bys-coins', builder: (context, state) => const BysCoinsScreen()),
      GoRoute(path: '/referral', builder: (context, state) => const ReferralScreen()),
      GoRoute(path: '/referral-history', builder: (context, state) => const ReferralHistoryScreen()),
      GoRoute(path: '/support-center', builder: (context, state) => const SupportCenterScreen()),
      GoRoute(path: '/faqs', builder: (context, state) => const FaqsScreen()),
      GoRoute(path: '/terms-conditions', builder: (context, state) => const TermsConditionsScreen()),
      GoRoute(path: '/about-us', builder: (context, state) => const AboutUsScreen()),
      GoRoute(path: '/logout', builder: (context, state) => const LogoutConfirmationScreen()),

      // 9. Admin & Venue Owner
      GoRoute(path: '/analytics-dashboard', builder: (context, state) => const AnalyticsDashboardScreen()),
      GoRoute(path: '/admin-dashboard', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/venue-owner-dashboard', builder: (context, state) => const TurfOwnerDashboardScreen()),
      GoRoute(path: '/venue-calendar', builder: (context, state) => const VenueCalendarScreen()),
      GoRoute(path: '/venue-earnings', builder: (context, state) => const VenueEarningsScreen()),
      GoRoute(path: '/venue-reviews', builder: (context, state) => const VenueReviewsScreen()),
      GoRoute(path: '/venue-settings', builder: (context, state) => const VenueSettingsScreen()),
      GoRoute(path: '/addons-management', builder: (context, state) => const AddonsManagementScreen()),
      GoRoute(path: '/live-booking-requests', builder: (context, state) => const LiveBookingRequestsScreen()),
      GoRoute(path: '/add-turf', builder: (context, state) => AddTurfScreen(turf: state.extra as dynamic)),
      GoRoute(path: '/admin/users', builder: (context, state) => const ManageUsersScreen()),

      // 10. Additional Modules
      GoRoute(path: '/community', builder: (context, state) => const CommunityFeedScreen()),
      GoRoute(path: '/store', builder: (context, state) => const StoreScreen()),
      GoRoute(path: '/coach', builder: (context, state) => const CoachBookingScreen()),
      GoRoute(path: '/stocks', builder: (context, state) => const StockSharesScreen()),
      GoRoute(
        path: '/weather',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return WeatherScreen(
            turfName: extra?['turfName'] as String?,
            location: extra?['location'] as String?,
          );
        },
      ),
    ],
  );
}
