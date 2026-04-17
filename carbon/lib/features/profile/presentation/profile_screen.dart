import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/profile/provider/profile_provider.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:carbon/shared/widgets/app_loader.dart';
import 'package:carbon/shared/widgets/app_card.dart';
import 'package:carbon/shared/widgets/core_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _refreshProfile() async {
    await ref.read(profileActionProvider).refreshProfile();
    ref.invalidate(profileAsyncProvider);
    await ref.read(profileAsyncProvider.future);
  }

  Future<void> _showEditProfileDialog(ProfileViewData profileView) async {
    final profile = profileView.profile;
    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email);
    final phoneController = TextEditingController(text: profile.phone);
    final zoneController = TextEditingController(text: profile.zone);
    String? validationError;

    final shouldSave =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return AlertDialog(
                  title: const Text('Edit Worker Profile'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: phoneController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: zoneController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(labelText: 'Zone'),
                        ),
                        if (validationError != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            validationError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        final zone = zoneController.text.trim();
                        final email = emailController.text.trim();

                        if (name.isEmpty || phone.isEmpty || zone.isEmpty) {
                          setDialogState(() {
                            validationError =
                                'Name, phone, and zone are required.';
                          });
                          return;
                        }

                        if (email.isNotEmpty &&
                            (!email.contains('@') || !email.contains('.'))) {
                          setDialogState(() {
                            validationError = 'Enter a valid email address.';
                          });
                          return;
                        }

                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!shouldSave) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      zoneController.dispose();
      return;
    }

    final success = await ref
        .read(profileActionProvider)
        .saveProfile(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          zone: zoneController.text.trim(),
        );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    zoneController.dispose();

    if (!mounted) {
      return;
    }

    if (!success) {
      final error =
          ref.read(profileActionErrorProvider) ??
          'Unable to save profile right now.';
      AppSnackbar.show(context, error, isError: true);
      return;
    }

    AppSnackbar.show(context, 'Profile updated successfully.');
  }

  @override
  Widget build(BuildContext context) {
    final profileView = ref.watch(profileProvider);
    final profile = profileView.profile;
    final workerStatus = profileView.status;
    final profileAsync = ref.watch(profileAsyncProvider);
    final profileError = ref.watch(profileErrorProvider);
    final actionError = ref.watch(profileActionErrorProvider);
    final actionLoading = ref.watch(profileActionLoadingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String? staleText;
    final syncedAt = profileView.lastSyncedAt;
    if (profileView.isStale && syncedAt != null) {
      staleText =
          'Showing cached data from ${syncedAt.hour.toString().padLeft(2, '0')}:${syncedAt.minute.toString().padLeft(2, '0')}.';
    } else if (profileView.isStale) {
      staleText = 'Showing cached profile data.';
    }

    return CoreScaffold(
      currentRoute: RouteNames.profile,
      title: 'Profile',
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (profileAsync.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SizedBox(height: 28, child: AppLoader()),
              ),
            if (profileError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  profileError,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            if (staleText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  staleText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            if (profileError != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _refreshProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry profile fetch'),
                ),
              ),
            if (profile.isIncomplete)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Some profile details are missing. Update your profile to avoid policy and claims issues.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            if (actionError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionError,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            AppCard(title: 'Name', subtitle: profile.displayName),
            AppCard(title: 'Email', subtitle: profile.displayEmail),
            AppCard(title: 'Phone', subtitle: profile.displayPhone),
            AppCard(title: 'Zone', subtitle: profile.displayZone),
            AppCard(
              title: 'Weekly Income',
              subtitle: profile.displayWeeklyIncome,
            ),
            AppCard(
              title: 'Coverage Status',
              subtitle: workerStatus.coverageLabel,
              trailing: _StatusBadge(
                text: workerStatus.coverageLabel,
                isPositive: workerStatus.isCoverageActive,
                isUnknown: workerStatus.isActive == null,
              ),
            ),
            AppCard(
              title: 'Claim Eligibility',
              subtitle: workerStatus.claimEligibilityLabel,
              trailing: _StatusBadge(
                text: workerStatus.claimEligibilityLabel,
                isPositive: workerStatus.canClaim,
                isUnknown: workerStatus.eligibleForClaim == null,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: actionLoading
                  ? null
                  : () => _showEditProfileDialog(profileView),
              icon: actionLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.edit_outlined),
              label: Text(actionLoading ? 'Saving...' : 'Edit & Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.isPositive,
    required this.isUnknown,
  });

  final String text;
  final bool isPositive;
  final bool isUnknown;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color backgroundColor;
    final Color foregroundColor;

    if (isUnknown) {
      backgroundColor = colorScheme.surfaceContainerHighest;
      foregroundColor = colorScheme.onSurfaceVariant;
    } else if (isPositive) {
      backgroundColor = colorScheme.primaryContainer;
      foregroundColor = colorScheme.onPrimaryContainer;
    } else {
      backgroundColor = colorScheme.errorContainer;
      foregroundColor = colorScheme.onErrorContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
