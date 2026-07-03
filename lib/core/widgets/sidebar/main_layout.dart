import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/widgets/sidebar/app_sidebar.dart';

/// Main layout wrapper that includes the sidebar navigation
/// Use this layout for all main pages after authentication
class MainLayout extends StatelessWidget {
  final String currentRoute;
  final bool isAdmin;
  final Widget child;
  final VoidCallback? onLogout;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onMessagesPressed;
  final VoidCallback? onHistoryPressed;
  final bool isChatOpen;

  const MainLayout({
    super.key,
    required this.currentRoute,
    this.isAdmin = false,
    required this.child,
    this.onLogout,
    this.onSettingsPressed,
    this.onNotificationsPressed,
    this.onMessagesPressed,
    this.onHistoryPressed,
    this.isChatOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar
          AppSidebar(
            currentRoute: currentRoute,
            isAdmin: isAdmin,
            onLogout: onLogout,
            onSettingsPressed: onSettingsPressed,
            onNotificationsPressed: onNotificationsPressed,
            onMessagesPressed: onMessagesPressed,
            onHistoryPressed: onHistoryPressed,
            isChatOpen: isChatOpen,
          ),
          // Main content
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
