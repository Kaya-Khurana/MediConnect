import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  // Controllers for everyone
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // Controllers for Doctors
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _feesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Controllers for Labs
  final TextEditingController _labNameController = TextEditingController();
  final TextEditingController _labAddressController = TextEditingController();
  final TextEditingController _labServicesController = TextEditingController();

  bool _isLogin = true; // Toggle between Login and Sign Up
  String _selectedRole = 'patient'; // Default role for signup
  String _errorMessage = '';

  // Function to toggle between Login and Signup forms
  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
      _selectedRole = 'patient'; // Reset role on toggle
      _errorMessage = '';
      // Clear specific fields when switching forms might be useful too
      _firstNameController.clear();
      _lastNameController.clear();
      _specialtyController.clear();
      _qualificationController.clear();
      _feesController.clear();
      _locationController.clear();
      _labNameController.clear();
      _labAddressController.clear();
      _labServicesController.clear();
    });
  }

  // Function to handle form submission (Login or Signup)
  void _submitForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Email and Password cannot be empty.";
      });
      return;
    }

    setState(() {
      _errorMessage = '';
    }); // Clear previous error

    if (_isLogin) {
      // --- LOGIN ---
      final userCredential =
          await _authService.signInWithEmail(email, password);
      if (userCredential == null) {
        setState(() {
          _errorMessage = "Login failed. Please check your credentials.";
        });
      }
      // AuthGate will handle navigation on success
    } else {
      // --- SIGN UP ---
      final firstName =
          _firstNameController.text.trim(); // User/Contact first name
      final lastName =
          _lastNameController.text.trim(); // User/Contact last name
      final role = _selectedRole; // Use the selected role

      if (firstName.isEmpty || lastName.isEmpty) {
        setState(() {
          _errorMessage = "Please fill in First and Last Name.";
        });
        return;
      }

      Map<String, dynamic>? doctorData;
      Map<String, dynamic>? labData;

      // Gather Doctor Data if selected
      if (role == 'doctor') {
        final specialty = _specialtyController.text.trim();
        final qualification = _qualificationController.text.trim();
        final feesText = _feesController.text.trim();
        final location = _locationController.text.trim();
        final fees = double.tryParse(feesText);

        if (specialty.isEmpty ||
            qualification.isEmpty ||
            feesText.isEmpty ||
            location.isEmpty ||
            fees == null) {
          setState(() {
            _errorMessage = "Please fill in all doctor fields correctly.";
          });
          return;
        }
        doctorData = {
          'specialty': specialty,
          'qualification': qualification,
          'consultationFee': fees,
          'clinicAddress': location,
          'title': 'Dr.', // Default title
          'bio': '', // Default empty bio
        };
      }
      // Gather Lab Data if selected
      else if (role == 'lab') {
        final labName = _labNameController.text.trim();
        final labAddress = _labAddressController.text.trim();
        final labServices = _labServicesController.text.trim();

        if (labName.isEmpty || labAddress.isEmpty || labServices.isEmpty) {
          setState(() {
            _errorMessage = "Please fill in all laboratory fields.";
          });
          return;
        }
        labData = {
          'labName': labName,
          'address': labAddress,
          // Split services by comma and trim whitespace
          'services': labServices
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        };
      }

      // Call the updated signup function from AuthService
      final userCredential = await _authService.signUpWithEmail(
        email,
        password,
        firstName,
        lastName,
        role, // Pass the selected role
        doctorData: doctorData, // Will be null if not a doctor
        labData: labData, // Will be null if not a lab
      );

      if (userCredential == null) {
        // Use a more specific error if possible, otherwise generic
        setState(() {
          _errorMessage =
              "Sign up failed. The email might already be in use or the password is too weak.";
        });
      }
      // AuthGate handles navigation on success
    }
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _specialtyController.dispose();
    _qualificationController.dispose();
    _feesController.dispose();
    _locationController.dispose();
    _labNameController.dispose();
    _labAddressController.dispose();
    _labServicesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and Title
                    Image.asset('assets/mediconnect_logo.png', height: 80),
                    const SizedBox(height: 16),
                    Text(
                      _isLogin ? 'Welcome Back!' : 'Join MediConnect',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                    ),
                    Text(
                      _isLogin
                          ? 'Login to your account'
                          : 'Create a new account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // --- Name Fields (Only on Signup) ---
                    if (!_isLogin) ...[
                      TextField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: _selectedRole == 'lab'
                              ? 'Contact First Name'
                              : 'First Name',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: _selectedRole == 'lab'
                              ? 'Contact Last Name'
                              : 'Last Name',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- COMMON FIELDS (Email, Password) ---
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline)),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    // --- ROLE SELECTION (Only on Signup) ---
                    if (!_isLogin) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("Register as:",
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      RadioListTile<String>(
                        title: const Text('Patient'),
                        value: 'patient',
                        groupValue: _selectedRole,
                        onChanged: (value) =>
                            setState(() => _selectedRole = value!),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      RadioListTile<String>(
                        title: const Text('Doctor'),
                        value: 'doctor',
                        groupValue: _selectedRole,
                        onChanged: (value) =>
                            setState(() => _selectedRole = value!),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      RadioListTile<String>(
                        title: const Text('Laboratory'),
                        value: 'lab',
                        groupValue: _selectedRole,
                        onChanged: (value) =>
                            setState(() => _selectedRole = value!),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // --- End Role Selection ---

                    // --- CONDITIONAL FIELDS (Doctor / Lab) ---
                    if (!_isLogin)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // --- DOCTOR FIELDS ---
                            if (_selectedRole == 'doctor') ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              Text("Doctor's Profile",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: _specialtyController,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Specialty (e.g., Cardiologist)',
                                      prefixIcon: Icon(
                                          Icons.medical_services_outlined))),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: _qualificationController,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Qualification (e.g., MBBS, MD)',
                                      prefixIcon: Icon(Icons.school_outlined))),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: _feesController,
                                  decoration: const InputDecoration(
                                      labelText: 'Consultation Fee',
                                      prefixIcon:
                                          Icon(Icons.attach_money_outlined)),
                                  keyboardType: TextInputType.number),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: _locationController,
                                  decoration: const InputDecoration(
                                      labelText: 'Clinic Address',
                                      prefixIcon:
                                          Icon(Icons.location_on_outlined))),
                              const SizedBox(height: 16),
                            ],
                            // --- LAB FIELDS ---
                            if (_selectedRole == 'lab') ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              Text("Laboratory Details",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              TextFormField(
                                // Use TextFormField for validation
                                controller: _labNameController,
                                decoration: const InputDecoration(
                                    labelText: 'Laboratory Name',
                                    prefixIcon: Icon(Icons.business_outlined)),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _labAddressController,
                                decoration: const InputDecoration(
                                    labelText: 'Address',
                                    prefixIcon:
                                        Icon(Icons.location_on_outlined)),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _labServicesController,
                                decoration: const InputDecoration(
                                    labelText:
                                        'Services Offered (comma-separated)',
                                    prefixIcon: Icon(Icons.science_outlined)),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                            ]
                          ],
                        ),
                      ),
                    // --- End Conditional Fields ---

                    // Error Message
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
                    const SizedBox(height: 16),

                    // Toggle Button
                    TextButton(
                      onPressed: _toggleForm,
                      child: Text(
                        _isLogin
                            ? 'Don\'t have an account? Sign Up'
                            : 'Already have an account? Login',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
