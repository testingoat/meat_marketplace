import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../models/odoo_config.dart';
import '../../../services/odoo_api_service.dart';
import '../../../services/supabase_service.dart';

class OdooConfigForm extends StatefulWidget {
  final Function(OdooConfig) onConfigurationSaved;
  final bool isLoading;

  const OdooConfigForm({
    Key? key,
    required this.onConfigurationSaved,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<OdooConfigForm> createState() => _OdooConfigFormState();
}

class _OdooConfigFormState extends State<OdooConfigForm> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController =
      TextEditingController(text: 'https://goatgoat.xyz/');
  final _databaseController = TextEditingController(text: 'staging');
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin');
  final _apiKeyController = TextEditingController();

  bool _obscurePassword = true;
  bool _useApiKey = false;
  bool _isSaving = false;
  Set<String> _selectedFields = {'name', 'email', 'phone'};

  @override
  void initState() {
    super.initState();
    // Pre-populate with provided credentials
    _loadDefaultCredentials();
  }

  void _loadDefaultCredentials() {
    _serverUrlController.text = 'https://goatgoat.xyz/';
    _databaseController.text = 'staging';
    _usernameController.text = 'admin';
    _passwordController.text = 'admin';
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final client = await SupabaseService().client;
      final user = client.auth.currentUser;

      if (user == null) throw Exception('User not authenticated');

      final configData = {
        'user_id': user.id,
        'server_url': _serverUrlController.text.trim(),
        'database_name': _databaseController.text.trim(),
        'username': _usernameController.text.trim(),
        'fields_to_sync': _selectedFields.toList(),
        'sync_enabled': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Upsert configuration
      await client
          .from('odoo_configurations')
          .upsert(configData, onConflict: 'user_id');

      // Test connection
      final config = OdooConfig(
        serverUrl: _serverUrlController.text.trim(),
        database: _databaseController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        apiKey: _useApiKey ? _apiKeyController.text.trim() : '',
        isActive: true,
        webhookUrls: <String, String>{},
      );

      final odooService = OdooApiService();
      await odooService.initialize(config);
      final isConnected = await odooService.authenticate();

      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Odoo configuration saved and tested successfully!'),
            backgroundColor: Colors.green));
        widget.onConfigurationSaved(config);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Configuration saved but connection test failed'),
            backgroundColor: Colors.orange));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save configuration: $e'),
          backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withAlpha(26),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2)),
            ]),
        child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Odoo Server Configuration',
                  style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800])),

              SizedBox(height: 2.h),

              // Pre-configured notice
              Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                      color: Color(0xFF10B981).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Color(0xFF10B981).withAlpha(77))),
                  child: Row(children: [
                    Icon(Icons.check_circle,
                        color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 2.w),
                    Expanded(
                        child: Text(
                            'Configuration pre-filled with your Odoo credentials. You can modify if needed.',
                            style: GoogleFonts.inter(
                                fontSize: 11.sp, color: Color(0xFF065F46)))),
                  ])),

              SizedBox(height: 3.h),

              // Server URL
              _buildTextField(
                  controller: _serverUrlController,
                  label: 'Server URL',
                  hint: 'https://your-odoo-server.com',
                  icon: Icons.link,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Server URL is required';
                    }
                    if (!value!.startsWith('http')) {
                      return 'Please enter a valid URL starting with http or https';
                    }
                    return null;
                  }),

              SizedBox(height: 2.h),

              // Database
              _buildTextField(
                  controller: _databaseController,
                  label: 'Database Name',
                  hint: 'your-database-name',
                  icon: Icons.storage,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Database name is required';
                    }
                    return null;
                  }),

              SizedBox(height: 3.h),

              // Authentication method toggle
              Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Authentication Method',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800])),
                        SizedBox(height: 1.h),
                        Row(children: [
                          Expanded(
                              child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _useApiKey = false),
                                  child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 1.h, horizontal: 3.w),
                                      decoration: BoxDecoration(
                                          color: !_useApiKey
                                              ? Color(0xFF2B5CE6)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: !_useApiKey
                                                  ? Color(0xFF2B5CE6)
                                                  : Colors.grey[300]!)),
                                      child: Text('Username & Password',
                                          style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              color: !_useApiKey
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center)))),
                          SizedBox(width: 2.w),
                          Expanded(
                              child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _useApiKey = true),
                                  child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 1.h, horizontal: 3.w),
                                      decoration: BoxDecoration(
                                          color: _useApiKey
                                              ? Color(0xFF2B5CE6)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: _useApiKey
                                                  ? Color(0xFF2B5CE6)
                                                  : Colors.grey[300]!)),
                                      child: Text('API Key',
                                          style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              color: _useApiKey
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center)))),
                        ]),
                      ])),

              SizedBox(height: 2.h),

              // Authentication fields
              if (!_useApiKey) ...[
                // Username
                _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'your-username',
                    icon: Icons.person,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Username is required';
                      }
                      return null;
                    }),

                SizedBox(height: 2.h),

                // Password
                _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'your-password',
                    icon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey[600]),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword)),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Password is required';
                      }
                      return null;
                    }),
              ] else ...[
                // API Key
                _buildTextField(
                    controller: _apiKeyController,
                    label: 'API Key',
                    hint: 'your-api-key',
                    icon: Icons.key,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'API Key is required';
                      }
                      return null;
                    }),
              ],

              SizedBox(height: 3.h),

              // Help section
              Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Color(0xFF3B82F6).withAlpha(77))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.help_outline,
                              color: Color(0xFF3B82F6), size: 16),
                          SizedBox(width: 2.w),
                          Text('Configuration Help',
                              style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B82F6))),
                        ]),
                        SizedBox(height: 1.h),
                        Text(
                            '• Server URL: Your Odoo server address (e.g., https://yourcompany.odoo.com)\n'
                            '• Database: Your Odoo database name\n'
                            '• Username: Your Odoo login username\n'
                            '• Password: Your Odoo login password\n'
                            '• API Key: External API key from Odoo settings (if available)',
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.grey[700],
                                height: 1.4)),
                      ])),

              SizedBox(height: 3.h),

              // Save button
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                      onPressed: widget.isLoading ? null : _saveConfiguration,
                      icon: widget.isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)))
                          : Icon(Icons.save, size: 18),
                      label: Text(
                          widget.isLoading
                              ? 'Connecting to Odoo...'
                              : 'Save & Connect to Odoo',
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2B5CE6),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))))),
            ])));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700])),
      SizedBox(height: 0.5.h),
      TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF2B5CE6))),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFFEF4444))),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              filled: true,
              fillColor: Colors.grey[50]),
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey[800])),
    ]);
  }
}
