import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/viewmodels/auth_view_model.dart';
import 'package:recipe_app/views/widgets/custom_elevated_button.dart';
import 'package:recipe_app/views/screens/auth_wrapper.dart';
import 'package:recipe_app/views/auth/sign_in_screen.dart';
import 'package:recipe_app/views/screens/add_recipe_by_user/my_recipes_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(),
            const SizedBox(height: 20),
            const _SectionTitle('Your Preferences'),
            const SizedBox(height: 10),
            _ChipsRow(chips: const ['Vegetarian', 'Low sugar', 'Italian', 'Quick meals']),
            const SizedBox(height: 20),
            const _SectionTitle('Goals Summary'),
            const SizedBox(height: 10),
            _TwoStatsRow(
              leftTitle: 'Weekly Cooking',
              leftValue: '3–4 days',
              rightTitle: 'Cuisine Focus',
              rightValue: 'Mediterranean',
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Account'),
            const SizedBox(height: 10),
            _NavTile(
              icon: Icons.manage_accounts_outlined,
              title: 'Edit profile',
              subtitle: 'Name, photo, contact',
              onTap: () {},
            ),
            _NavTile(
              icon: Icons.subscriptions_outlined,
              title: 'Subscriptions',
              subtitle: 'Manage plan and billing',
              onTap: () {},
            ),
            _NavTile(
              icon: Icons.tune_outlined,
              title: 'Dietary preferences',
              subtitle: 'Allergies, dislikes, cuisines',
              onTap: () {},
            ),
            _NavTile(
              icon: Icons.book_outlined,
              title: 'My Recipes',
              subtitle: 'Your created recipes',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyRecipesScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            CustomElevatedButton(
              text: 'Log out',
              onPressed: () async {
                await context.read<AuthViewModel>().signOut();
                // Navigate to auth wrapper to check auth state
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;
    final displayName = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!
        : 'Recipeflow User';
    final emailText = user?.email ?? 'user@example.com';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 64,
                height: 64,
                color: Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(emailText, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepOrange,
              side: const BorderSide(color: Colors.deepOrange),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Edit'),
          )
        ],
      ),
    );
  }
}

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _ChangePasswordSection extends StatefulWidget {
  @override
  State<_ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends State<_ChangePasswordSection> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _currentController,
          obscureText: _obscureCurrent,
          decoration: InputDecoration(
            labelText: 'Current Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 12),
        CustomElevatedButton(
          text: authVm.isLoading ? 'Changing...' : 'Change Password',
          onPressed: authVm.isLoading
              ? null
              : () async {
                  final current = _currentController.text;
                  final np = _newController.text;
                  final cp = _confirmController.text;
                  if (current.isEmpty || np.isEmpty || cp.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(duration: Duration(seconds: 3), content: Text('Please fill all password fields')),
                    );
                    return;
                  }
                  if (np.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(duration: Duration(seconds: 3), content: Text('New password must be at least 6 characters')),
                    );
                    return;
                  }
                  if (np != cp) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(duration: Duration(seconds: 3), content: Text('New passwords do not match')),
                    );
                    return;
                  }
                  final ok = await context.read<AuthViewModel>().changePassword(currentPassword: current, newPassword: np);
                  if (!mounted) return;
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(duration: Duration(seconds: 3), content: Text('Password changed successfully')),
                    );
                    _currentController.clear();
                    _newController.clear();
                    _confirmController.clear();
                  } else {
                    final msg = context.read<AuthViewModel>().errorMessage ?? 'Failed to change password';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(duration: const Duration(seconds: 3), content: Text(msg)),
                    );
                  }
                },
        ),
      ],
    );
  }
}
class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Account Settings'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: authVm.isLoading
                ? null
                : () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your name')),
                      );
                      return;
                    }
                    await context.read<AuthViewModel>().updateDisplayName(name);
                    if (mounted && authVm.errorMessage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated')),
                      );
                      Navigator.of(context).pop();
                    }
                  },
            child: Text(
              authVm.isLoading ? 'Saving...' : 'Save',
              style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Name', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Your Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              if (authVm.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(authVm.errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: CustomElevatedButton(
                  text: 'Change Password',
                  onPressed: authVm.isLoading
                      ? null
                      : () async {
                          final currentController = TextEditingController();
                          final newController = TextEditingController();
                          final confirmController = TextEditingController();
                          bool obscureCurrent = true;
                          bool obscureNew = true;
                          bool obscureConfirm = true;

                          await showDialog<void>(
                            context: context,
                            builder: (ctx) {
                              return StatefulBuilder(
                                builder: (ctx, setState) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text('Change Password'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: currentController,
                                          obscureText: obscureCurrent,
                                          decoration: InputDecoration(
                                            labelText: 'Current Password',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                                              onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: newController,
                                          obscureText: obscureNew,
                                          decoration: InputDecoration(
                                            labelText: 'New Password',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                                              onPressed: () => setState(() => obscureNew = !obscureNew),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: confirmController,
                                          obscureText: obscureConfirm,
                                          decoration: InputDecoration(
                                            labelText: 'Confirm New Password',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                              onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: authVm.isLoading
                                          ? null
                                          : () async {
                                              final current = currentController.text;
                                              final np = newController.text;
                                              final cp = confirmController.text;
                                              if (current.isEmpty || np.isEmpty || cp.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(duration: Duration(seconds: 3), content: Text('Please fill all password fields')),
                                                );
                                                return;
                                              }
                                              if (np.length < 6) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(duration: Duration(seconds: 3), content: Text('New password must be at least 6 characters')),
                                                );
                                                return;
                                              }
                                              if (np != cp) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(duration: Duration(seconds: 3), content: Text('New passwords do not match')),
                                                );
                                                return;
                                              }
                                              final ok = await context.read<AuthViewModel>().changePassword(currentPassword: current, newPassword: np);
                                              if (!mounted) return;
                                              if (ok) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(duration: Duration(seconds: 3), content: Text('Password changed successfully')),
                                                );
                                                Navigator.of(ctx).pop();
                                              } else {
                                                final msg = context.read<AuthViewModel>().errorMessage ?? 'Failed to change password';
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(duration: const Duration(seconds: 3), content: Text(msg)),
                                                );
                                              }
                                            },
                                      child: Text(
                                        authVm.isLoading ? 'Changing...' : 'Change',
                                        style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                onPressed: authVm.isLoading
                    ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('Delete Account'),
                              content: const Text('This action cannot be undone. Delete your account and all data?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            final ok = await context.read<AuthViewModel>().deleteAccount();
                            if (!mounted) return;
                            if (ok) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const SignInScreen()),
                                (route) => false,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to delete account. Try re-signing in.')),
                              );
                            }
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Delete Account'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87));
  }
}

class _ChipsRow extends StatelessWidget {
  final List<String> chips;
  const _ChipsRow({required this.chips});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(e, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
              ))
          .toList(),
    );
  }
}

class _TwoStatsRow extends StatelessWidget {
  final String leftTitle;
  final String leftValue;
  final String rightTitle;
  final String rightValue;
  const _TwoStatsRow({
    required this.leftTitle,
    required this.leftValue,
    required this.rightTitle,
    required this.rightValue,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(title: leftTitle, value: leftValue)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: rightTitle, value: rightValue)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.title, this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: const TextStyle(color: Colors.black54)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}