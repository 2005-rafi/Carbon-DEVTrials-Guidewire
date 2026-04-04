import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/profile/provider/profile_provider.dart';
import 'package:carbon/shared/widgets/app_card.dart';
import 'package:carbon/shared/widgets/core_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return CoreScaffold(
      currentRoute: RouteNames.profile,
      title: 'Profile',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          AppCard(title: 'Name', subtitle: profile['name'] ?? '-'),
          AppCard(title: 'Email', subtitle: profile['email'] ?? '-'),
          AppCard(title: 'Plan', subtitle: profile['plan'] ?? '-'),
        ],
      ),
    );
  }
}
