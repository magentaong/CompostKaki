import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  Future<void> _loadProfile() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;
    
    try {
      final supabaseService = SupabaseService();
      final response = await supabaseService.client
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('id', user.id)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _profile = response != null ? Map<String, dynamic>.from(response) : null;
        });
      }
    } catch (e) {
      // Silently fail - we'll fall back to userMetadata
    }
  }
  void _showDeleteAccountDialog(BuildContext context) {
    final authService = context.read<AuthService>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => _DeleteAccountDialog(
        onDelete: () async {
          try {
            await authService.deleteAccount();
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            if (context.mounted) {
              context.go('/login');
            }
          } catch (e) {
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete account: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentEmail = authService.currentUser?.email ?? '';
    
    showDialog(
      context: context,
      builder: (dialogContext) => _ResetPasswordDialog(
        currentEmail: currentEmail,
        onReset: (email) async {
          try {
            await authService.resetPassword(email);
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset email sent! Please check your inbox.'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            }
          } catch (e) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text('Failed to send reset email: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final email = user?.email ?? '';
    
    // Get firstName and lastName from profiles table (source of truth), fallback to userMetadata
    final firstName = _profile?['first_name'] as String? ?? 
                      user?.userMetadata?['first_name'] as String? ?? '';
    final lastName = _profile?['last_name'] as String? ?? 
                     user?.userMetadata?['last_name'] as String? ?? '';
    
    // Build avatar initials safely
    String getAvatarInitials() {
      String firstInitial = '';
      String lastInitial = '';
      
      if (firstName.isNotEmpty) {
        firstInitial = firstName[0];
      } else if (email.isNotEmpty) {
        firstInitial = email[0];
      } else {
        firstInitial = 'U'; // Fallback to 'U' for User
      }
      
      if (lastName.isNotEmpty) {
        lastInitial = lastName[0];
      }
      
      return '$firstInitial$lastInitial'.toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      getAvatarInitials(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$firstName $lastName'.trim().isEmpty ? email : '$firstName $lastName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Settings
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/profile/edit');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock_reset, color: AppTheme.primaryGreen),
                  title: const Text('Reset Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showResetPasswordDialog(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      await authService.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  final String currentEmail;
  final Future<void> Function(String) onReset;

  const _ResetPasswordDialog({
    required this.currentEmail,
    required this.onReset,
  });

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.currentEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onReset(_emailController.text);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_reset, color: AppTheme.primaryGreen),
          SizedBox(width: 8),
          Text('Reset Password'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleReset,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Reset Link'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  final Future<void> Function() onDelete;

  const _DeleteAccountDialog({
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Account'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete your account?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'This action cannot be undone. All your data will be permanently deleted, including:',
            style: TextStyle(color: AppTheme.textGray),
          ),
          SizedBox(height: 8),
          Text('• Your profile', style: TextStyle(color: AppTheme.textGray)),
          Text('• All bins you own', style: TextStyle(color: AppTheme.textGray)),
          Text('• Your messages (will be anonymized)', style: TextStyle(color: AppTheme.textGray)),
          Text('• All your tasks', style: TextStyle(color: AppTheme.textGray)),
          SizedBox(height: 12),
          Text(
            'If you own bins, they will be deleted along with all their data.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await onDelete();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete Account'),
        ),
      ],
    );
  }
}

