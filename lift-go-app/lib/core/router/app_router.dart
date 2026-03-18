import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/quotes/screens/quotes_list_screen.dart';
import '../../features/quotes/screens/quote_detail_screen.dart';
import '../../features/quotes/screens/quote_request_screen.dart';
import '../../features/jobs/screens/jobs_list_screen.dart';
import '../../features/jobs/screens/job_detail_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/documents/screens/documents_screen.dart';
import '../../features/finance/screens/invoices_screen.dart';
import '../../features/finance/screens/invoice_detail_screen.dart';
import '../../features/support/screens/support_screen.dart';
import '../../features/support/screens/ticket_detail_screen.dart';
import '../../features/support/screens/new_claim_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';

// Shell scaffold key for the bottom-nav shell route
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      // While auth is loading, stay on current page
      if (authState.isLoading) return null;

      final isAuthenticated = authState.value?.isAuthenticated ?? false;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/onboarding';

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Authenticated shell — bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return HomeScreen(child: child, location: state.matchedLocation);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeTabPlaceholder(),
          ),
          GoRoute(
            path: '/quotes',
            builder: (context, state) => const QuotesListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => QuoteDetailScreen(
                  quoteId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/jobs',
            builder: (context, state) => const JobsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => JobDetailScreen(
                  jobId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'inventory',
                    builder: (context, state) => InventoryScreen(
                      jobId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportScreen(),
            routes: [
              GoRoute(
                path: 'tickets/:id',
                builder: (context, state) => TicketDetailScreen(
                  ticketId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'claims/new',
                builder: (context, state) => const NewClaimScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Routes outside the shell (full screen)
      GoRoute(
        path: '/quote/new',
        builder: (context, state) => const QuoteRequestScreen(),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoicesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => InvoiceDetailScreen(
              invoiceId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});

/// Placeholder widget used as the home tab child in the shell
class HomeTabPlaceholder extends StatelessWidget {
  const HomeTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
